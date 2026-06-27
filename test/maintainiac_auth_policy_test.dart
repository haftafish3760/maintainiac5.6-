import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/maintainiac_auth_policy.dart';

void main() {
  test('hosted account login allows only Google and Apple providers', () {
    expect(MaintainiacAuthPolicy.isAllowedProviderId('google.com'), isTrue);
    expect(MaintainiacAuthPolicy.isAllowedProviderId('apple.com'), isTrue);

    for (final deniedProvider in MaintainiacAuthPolicy.deniedProviderIds) {
      expect(
        MaintainiacAuthPolicy.isAllowedProviderId(deniedProvider),
        isFalse,
        reason: '$deniedProvider should not become a login provider.',
      );
    }
  });

  test('allowed provider set remains intentionally small', () {
    expect(MaintainiacAuthPolicy.allowedProviders, {
      MaintainiacAuthProvider.google,
      MaintainiacAuthProvider.apple,
    });
  });
}
