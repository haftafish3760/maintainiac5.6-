const {createHmac} = require('node:crypto');
const {Timestamp} = require('firebase-admin/firestore');
const {HttpsError} = require('firebase-functions/v2/https');
const {defineInt} = require('firebase-functions/params');

const SHA256 = /^[a-f0-9]{64}$/;
const ALLOWED_PROVIDERS = new Set(['google.com', 'apple.com']);
const WINDOW_MILLIS = 30 * 24 * 60 * 60 * 1000;
const freeAccountsPerInstall = defineInt(
  'ACCOUNT_ABUSE_FREE_ACCOUNTS_PER_INSTALL',
  {default: 2},
);
const freeAccountsPerNetworkWindow = defineInt(
  'ACCOUNT_ABUSE_FREE_ACCOUNTS_PER_NETWORK_WINDOW',
  {default: 20},
);
const hardAccountsPerInstall = defineInt(
  'ACCOUNT_ABUSE_HARD_ACCOUNTS_PER_INSTALL',
  {default: 6},
);
const hardAccountsPerNetworkWindow = defineInt(
  'ACCOUNT_ABUSE_HARD_ACCOUNTS_PER_NETWORK_WINDOW',
  {default: 100},
);

function accountAbuseInput(request, {allowEmulatorProvider = false} = {}) {
  const uid = request.auth?.uid || '';
  const installationHash = String(
    request.data?.appInstallationHash || '',
  ).trim();
  const providerId = String(
    request.auth?.token?.firebase?.sign_in_provider || '',
  ).trim();
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  if (!SHA256.test(installationHash)) {
    throw new HttpsError(
      'invalid-argument',
      'A valid app installation identity is required.',
    );
  }
  if (!ALLOWED_PROVIDERS.has(providerId) &&
      !(allowEmulatorProvider && ['password', 'anonymous', 'custom'].includes(
        providerId,
      ))) {
    throw new HttpsError(
      'permission-denied',
      'Hosted accounts require Google or Apple sign-in.',
    );
  }
  return {uid, installationHash, providerId};
}

function accountAbuseLimits() {
  const limits = {
    freeInstall: freeAccountsPerInstall.value(),
    freeNetwork: freeAccountsPerNetworkWindow.value(),
    hardInstall: hardAccountsPerInstall.value(),
    hardNetwork: hardAccountsPerNetworkWindow.value(),
  };
  if (!Number.isInteger(limits.freeInstall) || limits.freeInstall < 1 ||
      limits.freeInstall > 10 ||
      !Number.isInteger(limits.freeNetwork) || limits.freeNetwork < 5 ||
      limits.freeNetwork > 500 ||
      !Number.isInteger(limits.hardInstall) ||
      limits.hardInstall <= limits.freeInstall || limits.hardInstall > 25 ||
      !Number.isInteger(limits.hardNetwork) ||
      limits.hardNetwork <= limits.freeNetwork || limits.hardNetwork > 1000) {
    throw new HttpsError(
      'failed-precondition',
      'Hosted account protection configuration is invalid.',
    );
  }
  return limits;
}

function networkWindowIdentity(
  request,
  pepper,
  nowMillis = Date.now(),
  {emulatorFallback = false} = {},
) {
  if (typeof pepper !== 'string' || pepper.length < 32) {
    throw new HttpsError(
      'failed-precondition',
      'Hosted account network protection is unavailable.',
    );
  }
  const rawIp = String(
    request.rawRequest?.ip ||
    request.rawRequest?.socket?.remoteAddress ||
    '',
  ).trim();
  const coarseIp = coarseNetwork(rawIp) ||
    (emulatorFallback ? '127.0.0.0/24' : '');
  if (!coarseIp) {
    throw new HttpsError(
      'failed-precondition',
      'Hosted account network protection could not verify this request.',
    );
  }
  const windowNumber = Math.floor(nowMillis / WINDOW_MILLIS);
  const digest = createHmac('sha256', pepper)
    .update(`${windowNumber}\u0000${coarseIp}`)
    .digest('hex');
  return {
    id: digest,
    windowNumber,
    windowStartedAt: Timestamp.fromMillis(windowNumber * WINDOW_MILLIS),
  };
}

function coarseNetwork(rawIp) {
  const value = rawIp.replace(/^::ffff:/, '').split('%')[0];
  const ipv4 = value.split('.');
  if (ipv4.length === 4 && ipv4.every((part) => {
    const number = Number(part);
    return Number.isInteger(number) && number >= 0 && number <= 255;
  })) {
    return `${ipv4[0]}.${ipv4[1]}.${ipv4[2]}.0/24`;
  }
  const ipv6 = value.toLowerCase();
  if (/^[a-f0-9:]+$/.test(ipv6) && ipv6.includes(':')) {
    const groups = expandedIpv6Groups(ipv6);
    if (groups) return `${groups.slice(0, 3).join(':')}::/48`;
  }
  return '';
}

function expandedIpv6Groups(value) {
  const pieces = value.split('::');
  if (pieces.length > 2) return null;
  const left = pieces[0] ? pieces[0].split(':') : [];
  const right = pieces.length === 2 && pieces[1] ? pieces[1].split(':') : [];
  if (left.some((part) => !/^[a-f0-9]{1,4}$/.test(part)) ||
      right.some((part) => !/^[a-f0-9]{1,4}$/.test(part))) return null;
  const missing = 8 - left.length - right.length;
  if (missing < 0 || (pieces.length === 1 && missing !== 0)) return null;
  return [...left, ...Array(missing).fill('0'), ...right]
    .map((part) => part.padStart(4, '0'));
}

function accountIds(data) {
  const ids = data?.accountUids;
  if (ids == null) return [];
  if (!Array.isArray(ids) || ids.length > 100 ||
      ids.some((uid) => typeof uid !== 'string' || uid.length < 1 ||
        uid.length > 160)) {
    throw new HttpsError(
      'failed-precondition',
      'Hosted account protection data requires review.',
    );
  }
  return [...new Set(ids)];
}

function requireAccountGrant({
  uid,
  installData,
  networkData,
  verificationData,
  limits,
  hasEntitlement = false,
}) {
  const installAccounts = accountIds(installData);
  const networkAccounts = accountIds(networkData);
  const existing = installAccounts.includes(uid);
  if (installData?.status === 'blocked' || networkData?.status === 'blocked') {
    deny('This signup signal requires account review.');
  }
  if (!hasEntitlement && !existing &&
      (installAccounts.length >= limits.hardInstall ||
      networkAccounts.length >= limits.hardNetwork)) {
    deny('This signup signal requires manual review.');
  }
  const additionalVerification =
    verificationData?.uid === uid &&
    verificationData?.status === 'approved' &&
    verificationData?.expiresAt?.toMillis?.() > Date.now();
  if (!hasEntitlement && !existing && !additionalVerification &&
      (installAccounts.length >= limits.freeInstall ||
        networkAccounts.length >= limits.freeNetwork)) {
    throw new HttpsError(
      'failed-precondition',
      'Additional account verification is required.',
      {reason: 'additional_verification_required'},
    );
  }
  return {
    installAccounts,
    networkAccounts,
    existing,
    additionalVerification,
  };
}

function abuseLedgerDocument({accounts, status, now, extra = {}}) {
  return {
    schema: 'maintainiac_account_abuse_ledger_v1',
    accountUids: accounts,
    accountCount: accounts.length,
    status,
    ...extra,
    createdAt: extra.createdAt || now,
    updatedAt: now,
  };
}

function deny(message) {
  throw new HttpsError('permission-denied', message);
}

module.exports = {
  accountAbuseInput,
  accountAbuseLimits,
  abuseLedgerDocument,
  coarseNetwork,
  networkWindowIdentity,
  requireAccountGrant,
};
