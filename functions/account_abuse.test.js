const assert = require('node:assert/strict');
const {describe, test} = require('node:test');
const {
  accountAbuseInput,
  coarseNetwork,
  requireAccountGrant,
} = require('./account_abuse');

const installHash = 'a'.repeat(64);
const limits = {
  freeInstall: 2,
  freeNetwork: 20,
  hardInstall: 6,
  hardNetwork: 100,
};

describe('account abuse boundary', () => {
  test('production input derives an allowed provider from auth context', () => {
    const input = accountAbuseInput(request('google.com'));
    assert.equal(input.providerId, 'google.com');
    assert.equal(input.installationHash, installHash);
  });

  test('client data cannot claim an allowed provider', () => {
    assert.throws(
      () => accountAbuseInput(request('password', {providerId: 'google.com'})),
      /Google or Apple sign-in/,
    );
  });

  test('emulator-only provider exception is explicit', () => {
    const input = accountAbuseInput(request('password'), {
      allowEmulatorProvider: true,
    });
    assert.equal(input.providerId, 'password');
  });

  test('coarse network signal never preserves a complete address', () => {
    assert.equal(coarseNetwork('192.0.2.44'), '192.0.2.0/24');
    assert.equal(
      coarseNetwork('2001:db8:abcd:1234::7'),
      '2001:0db8:abcd::/48',
    );
  });

  test('third free account requires server-side verification', () => {
    assert.throws(
      () => requireAccountGrant({
        uid: 'uid-3',
        installData: {accountUids: ['uid-1', 'uid-2']},
        networkData: {accountUids: []},
        verificationData: null,
        limits,
      }),
      /Additional account verification is required/,
    );
  });

  test('existing entitlement remains recoverable on a replacement device', () => {
    const grant = requireAccountGrant({
      uid: 'uid-existing',
      installData: {accountUids: ['uid-1', 'uid-2']},
      networkData: {accountUids: Array.from({length: 20}, (_, i) => `n-${i}`)},
      verificationData: null,
      limits,
      hasEntitlement: true,
    });
    assert.equal(grant.existing, false);
  });
});

function request(providerId, data = {}) {
  return {
    auth: {
      uid: 'uid-1',
      token: {firebase: {sign_in_provider: providerId}},
    },
    data: {appInstallationHash: installHash, ...data},
  };
}
