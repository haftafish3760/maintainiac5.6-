enum MaintainiacAuthProvider {
  google('google.com', 'Google'),
  apple('apple.com', 'Apple');

  const MaintainiacAuthProvider(this.providerId, this.label);

  final String providerId;
  final String label;
}

class MaintainiacAuthPolicy {
  const MaintainiacAuthPolicy._();

  static const allowedProviders = {
    MaintainiacAuthProvider.google,
    MaintainiacAuthProvider.apple,
  };

  static const deniedProviderIds = {
    'password',
    'phone',
    'anonymous',
    'emailLink',
  };

  static bool isAllowedProviderId(String providerId) {
    return allowedProviders.any(
      (provider) => provider.providerId == providerId,
    );
  }
}
