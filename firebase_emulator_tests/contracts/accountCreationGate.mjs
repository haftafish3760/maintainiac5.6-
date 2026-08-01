export const accountCreationGateConfig = Object.freeze({
  allowedProviders: ['google.com', 'apple.com'],
  freeAccountsPerInstall: 2,
  freeAccountsPerIpWindow: 2,
  manualReviewAccountsPerInstall: 6,
  manualReviewAccountsPerIpWindow: 6,
  ipWindowDays: 30,
});

export function evaluateAccountCreationGate(signal) {
  if (!accountCreationGateConfig.allowedProviders.includes(signal.providerId)) {
    return block('Only Google and Apple sign-in are allowed.');
  }
  if (signal.appCheckVerified !== true) {
    return block('App Check verification is required.');
  }
  if (!looksLikeInstallationHash(signal.appInstallationHash)) {
    return block('Valid app installation signal is required.');
  }
  if (signal.installMarkedAbusive || signal.ipWindowMarkedAbusive) {
    return block('Signup signal is marked abusive.');
  }
  if (
    signal.accountsForInstall >=
      accountCreationGateConfig.manualReviewAccountsPerInstall ||
    signal.accountsForIpWindow >=
      accountCreationGateConfig.manualReviewAccountsPerIpWindow
  ) {
    return block('Manual review is required.');
  }
  if (
    signal.additionalVerificationSatisfied !== true &&
    (signal.accountsForInstall >=
      accountCreationGateConfig.freeAccountsPerInstall ||
      signal.accountsForIpWindow >=
        accountCreationGateConfig.freeAccountsPerIpWindow)
  ) {
    return {
      action: 'requireAdditionalVerification',
      reason: 'Device or network account threshold reached.',
    };
  }
  return { action: 'allow', reason: 'Signup is inside launch limits.' };
}

function block(reason) {
  return { action: 'block', reason };
}

function looksLikeInstallationHash(value) {
  return /^[a-f0-9]{64}$/.test(value ?? '');
}
