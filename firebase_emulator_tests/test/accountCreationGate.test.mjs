import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, test } from 'node:test';

import {
  accountCreationGateConfig,
  evaluateAccountCreationGate,
} from '../contracts/accountCreationGate.mjs';

import { assertEmulatorOnly } from './emulatorGuard.mjs';

describe('account creation Cloud Functions contract', () => {
  test('runs only with emulator guard satisfied', () => {
    assertEmulatorOnly();
  });

  test('allows the first two verified Google or Apple account signals', () => {
    for (const providerId of ['google.com', 'apple.com']) {
      const result = evaluateAccountCreationGate({
        providerId,
        appCheckVerified: true,
        appInstallationId: 'mai_install_12345678901234567890123456789012',
        accountsForInstall: 1,
        accountsForIpWindow: 1,
      });

      assert.equal(result.action, 'allow');
    }
  });

  test('requires additional verification after install or IP threshold', () => {
    const installResult = evaluateAccountCreationGate({
      providerId: 'google.com',
      appCheckVerified: true,
      appInstallationId: 'mai_install_12345678901234567890123456789012',
      accountsForInstall: 2,
      accountsForIpWindow: 0,
    });
    const ipResult = evaluateAccountCreationGate({
      providerId: 'apple.com',
      appCheckVerified: true,
      appInstallationId: 'mai_install_abcdefghijklmnopqrstuvwxyzABCDEF',
      accountsForInstall: 0,
      accountsForIpWindow: 2,
    });

    assert.equal(installResult.action, 'requireAdditionalVerification');
    assert.equal(ipResult.action, 'requireAdditionalVerification');
  });

  test('blocks unsupported provider, missing App Check, and bad install signal', () => {
    assert.equal(
      evaluateAccountCreationGate({
        providerId: 'password',
        appCheckVerified: true,
        appInstallationId: 'mai_install_12345678901234567890123456789012',
        accountsForInstall: 0,
        accountsForIpWindow: 0,
      }).action,
      'block',
    );
    assert.equal(
      evaluateAccountCreationGate({
        providerId: 'google.com',
        appCheckVerified: false,
        appInstallationId: 'mai_install_12345678901234567890123456789012',
        accountsForInstall: 0,
        accountsForIpWindow: 0,
      }).action,
      'block',
    );
    assert.equal(
      evaluateAccountCreationGate({
        providerId: 'google.com',
        appCheckVerified: true,
        appInstallationId: 'plain-device-id',
        accountsForInstall: 0,
        accountsForIpWindow: 0,
      }).action,
      'block',
    );
  });

  test('blocks heavy repeat attempts for manual review', () => {
    const result = evaluateAccountCreationGate({
      providerId: 'google.com',
      appCheckVerified: true,
      appInstallationId: 'mai_install_12345678901234567890123456789012',
      accountsForInstall: 6,
      accountsForIpWindow: 1,
      additionalVerificationSatisfied: true,
    });

    assert.equal(result.action, 'block');
    assert.match(result.reason, /Manual review/);
  });

  test('backend contract stays aligned with Dart threshold constants', () => {
    const dartPolicy = readFileSync(
      '../lib/shared/firebase/account_abuse_policy.dart',
      'utf8',
    );

    assert.match(
      dartPolicy,
      new RegExp(
        `freeAccountsPerInstall = ${accountCreationGateConfig.freeAccountsPerInstall}`,
      ),
    );
    assert.match(
      dartPolicy,
      new RegExp(
        `freeAccountsPerIpWindow = ${accountCreationGateConfig.freeAccountsPerIpWindow}`,
      ),
    );
    assert.match(
      dartPolicy,
      new RegExp(
        `manualReviewAccountsPerInstall = ${accountCreationGateConfig.manualReviewAccountsPerInstall}`,
      ),
    );
  });
});
