import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'maintainiac_firestore_schema.dart';

/// Establishes the minimum server-side workspace required for an opted-in,
/// independent user to back up their own records.
///
/// Fleet membership remains a separate server-managed workflow. This class is
/// intentionally limited to the user's private, owner-only workspace.
abstract interface class MaintainiacOrganizationBootstrapWriter {
  Future<void> setDocument({
    required String path,
    required Map<String, Object?> data,
  });
}

class FirebaseOrganizationBootstrapWriter
    implements MaintainiacOrganizationBootstrapWriter {
  FirebaseOrganizationBootstrapWriter({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> setDocument({
    required String path,
    required Map<String, Object?> data,
  }) {
    return _firestore.doc(path).set(data, SetOptions(merge: true));
  }
}

class MaintainiacOrganizationBootstrapper {
  const MaintainiacOrganizationBootstrapper({required this.writer});

  static const _ownerPermissions = <String>[
    'recordExpenses',
    'addOwnReceipts',
    'editOwnReceipts',
    'viewAllExpenses',
    'editCompanyExpenses',
  ];
  static const _allowedModules = <String>['expenses', 'receiptProofs'];

  final MaintainiacOrganizationBootstrapWriter writer;

  /// Uses a deterministic opaque document ID rather than exposing a Firebase
  /// UID in the organization path.
  static String personalOrganizationIdFor(String authenticatedUid) {
    final uid = authenticatedUid.trim();
    if (uid.isEmpty) {
      throw ArgumentError.value(
        authenticatedUid,
        'authenticatedUid',
        'An authenticated user ID is required.',
      );
    }
    final digest = sha256.convert(utf8.encode('maintainiac-personal:$uid'));
    return 'personal_${digest.toString().substring(0, 32)}';
  }

  /// Safe to repeat after interrupted app starts. The organization is created
  /// first, then its sole owner membership is enrolled.
  Future<MaintainiacOrganizationWorkspace> ensurePersonalWorkspace({
    required String authenticatedUid,
    DateTime? nowUtc,
  }) async {
    final uid = authenticatedUid.trim();
    final organizationId = personalOrganizationIdFor(uid);
    final timestamp = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final orgPath = '${MaintainiacFirestoreSchema.orgs}/$organizationId';
    await writer.setDocument(
      path: orgPath,
      data: {
        'schema': 'maintainiac_personal_workspace_v1',
        'ownerUid': uid,
        'organizationKind': 'independent_personal',
        'name': 'Personal workspace',
        'syncEnabled': true,
        'createdAt': timestamp.toIso8601String(),
        'updatedAt': timestamp.toIso8601String(),
      },
    );
    await writer.setDocument(
      path: '$orgPath/${MaintainiacFirestoreSchema.orgMembers}/$uid',
      data: {
        'schema': 'maintainiac_member_v1',
        'uid': uid,
        'orgId': organizationId,
        'status': 'active',
        'role': 'owner',
        'permissions': _ownerPermissions,
        'allowedModules': _allowedModules,
        'createdAt': timestamp.toIso8601String(),
        'updatedAt': timestamp.toIso8601String(),
      },
    );
    return MaintainiacOrganizationWorkspace(
      organizationId: organizationId,
      ownerUid: uid,
    );
  }
}

class MaintainiacOrganizationWorkspace {
  const MaintainiacOrganizationWorkspace({
    required this.organizationId,
    required this.ownerUid,
  });

  final String organizationId;
  final String ownerUid;
}
