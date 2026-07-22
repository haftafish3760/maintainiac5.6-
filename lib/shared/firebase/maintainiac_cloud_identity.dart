import 'package:firebase_auth/firebase_auth.dart';

/// Read-only identity boundary for backup coordinators. Authentication flows
/// remain in the shared auth service; feature modules receive only a UID.
abstract interface class MaintainiacCloudIdentityProvider {
  String? get currentUid;
}

class FirebaseMaintainiacCloudIdentityProvider
    implements MaintainiacCloudIdentityProvider {
  FirebaseMaintainiacCloudIdentityProvider({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;
}
