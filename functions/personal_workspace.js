const {createHash} = require('node:crypto');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineString} = require('firebase-functions/params');
const {
  accountAbuseInput,
  accountAbuseLimits,
  abuseLedgerDocument,
  networkWindowIdentity,
  requireAccountGrant,
} = require('./account_abuse');

const PLAN = /^[A-Za-z0-9_.-]{1,80}$/;
const defaultFreePlanId = defineString(
  'DEFAULT_FREE_PLAN_ID',
  {default: 'freeConfigurable'},
);
const OWNER_PERMISSIONS = [
  'recordExpenses',
  'addOwnReceipts',
  'editOwnReceipts',
  'viewAllExpenses',
  'editCompanyExpenses',
];

function buildPersonalWorkspaceFunctions({
  enforceAppCheck,
  ipHashPepper,
  allowEmulatorProvider = false,
  secrets = [],
}) {
  const handler = (request) => bootstrapPersonalWorkspace(request, {
    ipHashPepper,
    allowEmulatorProvider,
  });
  return {
    bootstrapPersonalWorkspace: onCall(
      {enforceAppCheck, secrets},
      handler,
    ),
    requestHostedAccountCreation: onCall(
      {enforceAppCheck, secrets},
      handler,
    ),
  };
}

async function bootstrapPersonalWorkspace(
  request,
  {ipHashPepper, allowEmulatorProvider},
) {
  const identity = accountAbuseInput(request, {allowEmulatorProvider});
  const uid = identity.uid;
  const planId = defaultFreePlanId.value();
  if (!PLAN.test(planId)) {
    throw new HttpsError(
      'failed-precondition',
      'Default hosted plan configuration is invalid.',
    );
  }
  const organizationId = personalOrganizationId(uid);
  const db = getFirestore();
  const orgRef = db.doc(`orgs/${organizationId}`);
  const memberRef = orgRef.collection('members').doc(uid);
  const entitlementRef = db.doc(`users/${uid}/entitlements/current`);
  const planRef = db.doc(`hostedPlans/${planId}`);
  const installRef = db.doc(
    `accountAbuseInstalls/${identity.installationHash}`,
  );
  const networkIdentity = networkWindowIdentity(
    request,
    ipHashPepper(),
    Date.now(),
    {emulatorFallback: allowEmulatorProvider},
  );
  const networkRef = db.doc(
    `accountAbuseIpWindows/${networkIdentity.id}`,
  );
  const verificationRef = db.doc(`accountCreationReviews/${uid}`);
  const limits = accountAbuseLimits();
  const result = await db.runTransaction(async (transaction) => {
    const [
      organization,
      member,
      entitlement,
      plan,
      install,
      network,
      verification,
    ] = await transaction.getAll(
      orgRef,
      memberRef,
      entitlementRef,
      planRef,
      installRef,
      networkRef,
      verificationRef,
    );
    if (organization.exists &&
        (organization.data()?.ownerUid !== uid ||
          organization.data()?.organizationKind !== 'independent_personal')) {
      throw new HttpsError(
        'permission-denied',
        'Personal workspace identity is already reserved.',
      );
    }
    if (member.exists &&
        (member.data()?.uid !== uid || member.data()?.orgId !== organizationId ||
          member.data()?.role !== 'owner' ||
          member.data()?.status !== 'active')) {
      throw new HttpsError(
        'permission-denied',
        'Personal workspace membership is invalid.',
      );
    }
    if (entitlement.exists &&
        (entitlement.data()?.uid !== uid ||
          entitlement.data()?.status !== 'active' ||
          !PLAN.test(String(entitlement.data()?.planId || '')))) {
      throw new HttpsError(
        'failed-precondition',
        'Hosted entitlement requires account review.',
      );
    }
    if (!entitlement.exists && plan.data()?.status !== 'active') {
      throw new HttpsError(
        'failed-precondition',
        'Default hosted plan is unavailable.',
      );
    }
    const grant = requireAccountGrant({
      uid,
      installData: install.data(),
      networkData: network.data(),
      verificationData: verification.data(),
      limits,
      hasEntitlement: entitlement.exists,
    });
    const now = Timestamp.now();
    if (!organization.exists) {
      transaction.create(orgRef, {
        schema: 'maintainiac_personal_workspace_v1',
        ownerUid: uid,
        organizationKind: 'independent_personal',
        name: 'Personal workspace',
        syncEnabled: true,
        createdAt: now,
        updatedAt: now,
      });
    }
    if (!member.exists) {
      transaction.create(memberRef, {
        schema: 'maintainiac_member_v1',
        uid,
        orgId: organizationId,
        status: 'active',
        role: 'owner',
        permissions: OWNER_PERMISSIONS,
        allowedModules: ['records', 'expenses', 'receiptProofs'],
        createdAt: now,
        updatedAt: now,
      });
    } else {
      const memberData = member.data();
      const permissions = mergeStrings(
        memberData.permissions,
        OWNER_PERMISSIONS,
      );
      const allowedModules = mergeStrings(
        memberData.allowedModules,
        ['records', 'expenses', 'receiptProofs'],
      );
      if (permissions.changed || allowedModules.changed) {
        transaction.update(memberRef, {
          permissions: permissions.values,
          allowedModules: allowedModules.values,
          updatedAt: now,
        });
      }
    }
    if (!entitlement.exists) {
      transaction.create(entitlementRef, {
        uid,
        planId,
        status: 'active',
        assignedBy: 'personal_workspace_bootstrap',
        initialAppInstallationHash: identity.installationHash,
        createdAt: now,
        updatedAt: now,
      });
    }
    const installAccounts = [...new Set([...grant.installAccounts, uid])];
    const networkAccounts = [...new Set([...grant.networkAccounts, uid])];
    transaction.set(installRef, abuseLedgerDocument({
      accounts: installAccounts,
      status: install.data()?.status || 'active',
      now,
      extra: {
        installationHash: identity.installationHash,
        identityVersion: 1,
        createdAt: install.data()?.createdAt,
      },
    }), {merge: false});
    transaction.set(networkRef, abuseLedgerDocument({
      accounts: networkAccounts,
      status: network.data()?.status || 'active',
      now,
      extra: {
        windowNumber: networkIdentity.windowNumber,
        windowStartedAt: networkIdentity.windowStartedAt,
        createdAt: network.data()?.createdAt,
      },
    }), {merge: false});
    return {
      organizationId,
      ownerUid: uid,
      planId: entitlement.data()?.planId || planId,
      installationHash: identity.installationHash,
    };
  });
  return result;
}

function mergeStrings(current, required) {
  const existing = Array.isArray(current) ? current : [];
  const values = [...new Set([...existing, ...required])];
  return {
    values,
    changed: values.length !== existing.length,
  };
}

function personalOrganizationId(uid) {
  const digest = createHash('sha256')
    .update(`maintainiac-personal:${uid}`)
    .digest('hex');
  return `personal_${digest.substring(0, 32)}`;
}

module.exports = {buildPersonalWorkspaceFunctions};
