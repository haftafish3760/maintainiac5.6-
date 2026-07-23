/// Public, module-neutral durable-storage surface for Maintainiac features.
///
/// Feature modules own their payload schemas and UI. This library owns the
/// local lifecycle, draft recovery, storage safety, cloud queue, tenant scope,
/// revision conflicts, and Firebase transport boundaries shared by all modules.
library;

export '../backup/cloud_backup_manifest.dart';
export '../backup/cloud_backup_quota.dart';
export '../backup/cloud_backup_service.dart';
export '../backup/cloud_backup_status.dart';
export '../firebase/hosted_sync_scope.dart';
export '../firebase/hosted_usage_limits.dart';
export '../firebase/maintainiac_callable_functions.dart';
export '../firebase/maintainiac_callable_durable_record_sink.dart';
export '../firebase/maintainiac_cloud_identity.dart';
export '../firebase/maintainiac_cloud_object_store.dart';
export '../firebase/maintainiac_durable_cloud_backup_gateway.dart';
export '../firebase/maintainiac_durable_cloud_revision_store.dart';
export '../firebase/maintainiac_durable_cloud_restore_gateway.dart';
export '../firebase/maintainiac_firestore_documents.dart';
export '../firebase/maintainiac_firestore_durable_record_codec.dart';
export '../firebase/maintainiac_firestore_revision_policy.dart';
export '../firebase/maintainiac_firestore_scope_policy.dart';
export '../firebase/maintainiac_firestore_upload_queue.dart';
export '../firebase/maintainiac_firebase_durable_storage_runtime.dart';
export '../firebase/maintainiac_hosted_plan_client.dart';
export '../firebase/maintainiac_hosted_restore_progress.dart';
export '../firebase/maintainiac_restore_credential_vault.dart';
export '../firebase/maintainiac_restore_callable_source.dart';
export '../firebase/maintainiac_restore_plan_client.dart';
export '../firebase/maintainiac_restore_session_client.dart';
export '../sync/maintainiac_sync_settings.dart';
export '../sync/maintainiac_sync_settings_store.dart';
export '../sync/maintainiac_sync_checkpoint_store.dart';
export '../sync/maintainiac_sync_orchestrator.dart';
export '../records/maintainiac_durable_record_store.dart';
export '../records/maintainiac_durable_payload.dart';
export '../records/maintainiac_cloud_restore_runner.dart';
export '../records/maintainiac_draft_autosave_coordinator.dart';
export '../records/maintainiac_draft_notification_dispatcher.dart';
export '../records/maintainiac_draft_reminder_coordinator.dart';
export '../records/maintainiac_draft_retention_policy.dart';
export '../records/maintainiac_record_lifecycle.dart';
export '../records/maintainiac_restore_contract.dart';
export '../records/maintainiac_restore_applier.dart';
export '../records/maintainiac_restore_batch_processor.dart';
export '../records/maintainiac_restore_session_store.dart';
export '../storage/app_storage_guard.dart';
export '../storage/app_storage_warning_preferences.dart';
