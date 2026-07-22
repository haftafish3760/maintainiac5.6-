/// Public, module-neutral durable-storage surface for Maintainiac features.
///
/// Feature modules own their payload schemas and UI. This library owns the
/// local lifecycle, draft recovery, storage safety, cloud queue, tenant scope,
/// revision conflicts, and Firebase transport boundaries shared by all modules.
library;

export '../firebase/hosted_sync_scope.dart';
export '../firebase/hosted_usage_limits.dart';
export '../firebase/maintainiac_callable_functions.dart';
export '../firebase/maintainiac_cloud_identity.dart';
export '../firebase/maintainiac_cloud_object_store.dart';
export '../firebase/maintainiac_firestore_documents.dart';
export '../firebase/maintainiac_firestore_revision_policy.dart';
export '../firebase/maintainiac_firestore_scope_policy.dart';
export '../firebase/maintainiac_firestore_upload_queue.dart';
export '../records/maintainiac_durable_record_store.dart';
export '../records/maintainiac_record_lifecycle.dart';
export '../storage/app_storage_guard.dart';
