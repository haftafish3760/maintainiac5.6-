import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/dashboard_trip_tracking_summary.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('trip summary exposes delivery dashboard profile tokens locally', () {
    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.deliveryVehicle,
      ),
    );

    expect(summary.dashboardMode, 'gig_driver');
    expect(summary.dashboardWidgetTokens, [
      'start_day',
      'live_odometer',
      'stops',
      'pay',
      'profit',
      'miles',
      'expenses',
    ]);
    expect(summary.quickActionTokens, [
      'add_pickup',
      'add_dropoff',
      'add_pay',
      'review_mileage',
    ]);
  });

  test('trip summary exposes contractor dashboard profile tokens locally', () {
    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.contractorVehicle,
      ),
    );

    expect(summary.dashboardMode, 'contractor');
    expect(summary.dashboardWidgetTokens, contains('jobs'));
    expect(summary.dashboardWidgetTokens, contains('materials'));
    expect(summary.dashboardWidgetTokens, contains('payments'));
    expect(summary.quickActionTokens, contains('add_job'));
    expect(summary.quickActionTokens, contains('record_payment'));
  });

  test('dashboard Firestore summary can carry only allowlisted UI tokens', () {
    final document =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 17, 12),
          dashboardMode: 'contractor',
          dashboardWidgetTokens: const [
            'start_day',
            'live_odometer',
            'jobs',
            'materials',
            'payments',
          ],
          quickActionTokens: const [
            'add_stop',
            'add_job',
            'record_payment',
            'review_mileage',
          ],
        );

    expect(document.data['dashboardWidgetTokens'], [
      'start_day',
      'live_odometer',
      'jobs',
      'materials',
      'payments',
    ]);
    expect(document.data['quickActionTokens'], [
      'add_stop',
      'add_job',
      'record_payment',
      'review_mileage',
    ]);
    expect(document.data.keys, isNot(contains('latitude')));
    expect(document.data.keys, isNot(contains('route')));

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(document),
      returnsNormally,
    );
  });

  test('dashboard Firestore builder rejects unknown UI tokens', () {
    expect(
      () => MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
        uid: 'firebaseUid-1',
        dashboardId: 'today',
        updatedAtUtc: DateTime.utc(2026, 7, 17, 12),
        dashboardWidgetTokens: const ['live_odometer', 'raw_route_map'],
      ),
      throwsArgumentError,
    );
    expect(
      () => MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
        uid: 'firebaseUid-1',
        dashboardId: 'today',
        updatedAtUtc: DateTime.utc(2026, 7, 17, 12),
        quickActionTokens: const ['add_pay', 'track_employee_live'],
      ),
      throwsArgumentError,
    );
  });

  test('dashboard upload policy rejects forged UI token lists', () {
    final good =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 17, 12),
          dashboardWidgetTokens: const ['live_odometer'],
          quickActionTokens: const ['review_mileage'],
        );
    final forged = MaintainiacFirestoreDocumentDraft(
      path: good.path,
      data: {
        ...good.data,
        'dashboardWidgetTokens': const ['live_odometer', 'latitude'],
      },
    );
    final oversized = MaintainiacFirestoreDocumentDraft(
      path: good.path,
      data: {
        ...good.data,
        'quickActionTokens': List<String>.filled(13, 'review_mileage'),
      },
    );

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(forged),
      throwsArgumentError,
    );
    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(oversized),
      throwsArgumentError,
    );
  });
}
