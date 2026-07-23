const {createHash} = require('node:crypto');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineString} = require('firebase-functions/params');

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

function buildPersonalWorkspaceFunctions({enforceAppCheck}) {
  return {
    bootstrapPersonalWorkspace: onCall(
      {enforceAppCheck},
      bootstrapPersonalWorkspace,
    ),
  };
}

async function bootstrapPersonalWorkspace(request) {
  const uid = request.auth?.uid || '';
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
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
  const result = await db.runTransaction(async (transaction) => {
    const [organization, member, entitlement] = await transaction.getAll(
      orgRef,
      memberRef,
      entitlementRef,
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
    if (!entitlement.exists) {
      const plan = await transaction.get(planRef);
      if (plan.data()?.status !== 'active') {
        throw new HttpsError(
          'failed-precondition',
          'Default hosted plan is unavailable.',
        );
      }
    }
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
        createdAt: now,
        updatedAt: now,
      });
    }
    return {
      organizationId,
      ownerUid: uid,
      planId: entitlement.data()?.planId || planId,
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
