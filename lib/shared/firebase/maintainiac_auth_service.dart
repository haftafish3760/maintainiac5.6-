import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'maintainiac_auth_policy.dart';

class MaintainiacAuthService {
  MaintainiacAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  static Future<void>? _googleSignInInitialization;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogleSignIn();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError('Google Sign-In is not available on this device.');
    }
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final identityToken = appleCredential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw StateError('Apple did not return an identity token.');
    }

    final oauthProvider = OAuthProvider(
      MaintainiacAuthProvider.apple.providerId,
    );
    final credential = oauthProvider.credential(
      idToken: identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  bool hasAllowedProvider(User user) {
    return user.providerData.any(
      (provider) =>
          MaintainiacAuthPolicy.isAllowedProviderId(provider.providerId),
    );
  }

  bool get canShowAppleSignIn => !kIsWeb;

  Future<void> _initializeGoogleSignIn() {
    return _googleSignInInitialization ??= _googleSignIn.initialize();
  }
}
