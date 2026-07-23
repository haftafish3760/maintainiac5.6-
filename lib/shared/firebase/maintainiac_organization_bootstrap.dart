import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'maintainiac_callable_functions.dart';

/// Atomic, server-authorized creation of an independent user's private
/// workspace. Clients never create organization, membership, or entitlement
/// documents directly.
abstract interface class MaintainiacOrganizationBootstrapGateway {
  Future<MaintainiacOrganizationWorkspace> ensurePersonalWorkspace({
    required String authenticatedUid,
  });
}

class CallableMaintainiacOrganizationBootstrapGateway
    implements MaintainiacOrganizationBootstrapGateway {
  CallableMaintainiacOrganizationBootstrapGateway({
    MaintainiacCallableFunctionClient? client,
  }) : _client = client ?? FirebaseMaintainiacCallableFunctionClient();

  final MaintainiacCallableFunctionClient _client;

  @override
  Future<MaintainiacOrganizationWorkspace> ensurePersonalWorkspace({
    required String authenticatedUid,
  }) async {
    final uid = authenticatedUid.trim();
    if (uid.isEmpty) {
      throw ArgumentError.value(
        authenticatedUid,
        'authenticatedUid',
        'An authenticated user ID is required.',
      );
    }
    final response = await _client.call(
      name: 'bootstrapPersonalWorkspace',
      data: const {},
    );
    final organizationId = response['organizationId'];
    final ownerUid = response['ownerUid'];
    final expectedOrganizationId =
        MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(uid);
    if (organizationId != expectedOrganizationId || ownerUid != uid) {
      throw const FormatException(
        'Hosted personal workspace identity did not match the signed-in user.',
      );
    }
    final planId = response['planId'];
    if (planId != null &&
        (planId is! String ||
            !RegExp(r'^[A-Za-z0-9_.-]{1,80}$').hasMatch(planId))) {
      throw const FormatException(
        'Hosted personal workspace plan identity is invalid.',
      );
    }
    return MaintainiacOrganizationWorkspace(
      organizationId: organizationId! as String,
      ownerUid: ownerUid! as String,
      planId: planId as String?,
    );
  }
}

class MaintainiacOrganizationBootstrapper {
  MaintainiacOrganizationBootstrapper({
    MaintainiacOrganizationBootstrapGateway? gateway,
  }) : _gateway = gateway ?? CallableMaintainiacOrganizationBootstrapGateway();

  final MaintainiacOrganizationBootstrapGateway _gateway;
  final Map<String, Future<MaintainiacOrganizationWorkspace>> _workspaceByUid =
      {};

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

  Future<MaintainiacOrganizationWorkspace> ensurePersonalWorkspace({
    required String authenticatedUid,
  }) async {
    final uid = authenticatedUid.trim();
    personalOrganizationIdFor(uid);
    final existing = _workspaceByUid[uid];
    if (existing != null) return existing;
    final pending = _gateway.ensurePersonalWorkspace(authenticatedUid: uid);
    _workspaceByUid[uid] = pending;
    try {
      return await pending;
    } catch (_) {
      if (identical(_workspaceByUid[uid], pending)) {
        _workspaceByUid.remove(uid);
      }
      rethrow;
    }
  }
}

class MaintainiacOrganizationWorkspace {
  const MaintainiacOrganizationWorkspace({
    required this.organizationId,
    required this.ownerUid,
    this.planId,
  });

  final String organizationId;
  final String ownerUid;
  final String? planId;
}
