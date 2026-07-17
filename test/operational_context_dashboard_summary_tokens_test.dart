import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/context/operational_context_models.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  test('operational context exports dashboard summary snake-case tokens', () {
    final context = ActiveOperationalContext.fromProfile(
      profile: UserProfileRecord(
        id: 'driver-1',
        name: 'Driver',
        type: UserProfileType.driver,
        role: UserRole.owner,
        permissions: permissionsForRole(UserRole.owner),
        cloudBackupEnabled: true,
      ),
      activeVehicleId: 'vehicle_1',
      activeVehicleLabel: 'Vehicle 1',
      activeVehicleUsage: VehicleUsage.businessPersonal,
      updatedAt: DateTime.utc(2026, 7, 17, 12),
    );

    expect(context.dashboardSummaryModeToken, 'gig_driver');
    expect(context.dashboardSummaryMileageToken, 'workday');
    expect(context.dashboardSummarySyncToken, 'firebase_backup');
  });

  test('fleet and employee context tokens match Firestore dashboard contract', () {
    final fleet = _context(
      dashboardMode: OperationalDashboardMode.fleetOwner,
      mileageMode: OperationalMileageMode.fleetReview,
      syncMode: OperationalSyncMode.companySync,
    );
    final employee = _context(
      dashboardMode: OperationalDashboardMode.employee,
      mileageMode: OperationalMileageMode.employeeShift,
      syncMode: OperationalSyncMode.localOnly,
    );

    expect(fleet.dashboardSummaryModeToken, 'fleet_owner');
    expect(fleet.dashboardSummaryMileageToken, 'fleet_review');
    expect(fleet.dashboardSummarySyncToken, 'company_sync');
    expect(employee.dashboardSummaryModeToken, 'employee');
    expect(employee.dashboardSummaryMileageToken, 'employee_shift');
    expect(employee.dashboardSummarySyncToken, 'local_only');
  });
}

ActiveOperationalContext _context({
  required OperationalDashboardMode dashboardMode,
  required OperationalMileageMode mileageMode,
  required OperationalSyncMode syncMode,
}) {
  return ActiveOperationalContext(
    userProfileId: 'user_1',
    userName: 'User',
    profileType: UserProfileType.contractor,
    role: UserRole.owner,
    permissions: permissionsForRole(UserRole.owner),
    companyMode: OperationalCompanyMode.solo,
    dashboardMode: dashboardMode,
    mileageMode: mileageMode,
    syncMode: syncMode,
    workProfileId: 'work_1',
    workProfileName: 'Work',
    activeVehicleId: 'vehicle_1',
    activeVehicleLabel: 'Vehicle 1',
    activeVehicleUsage: VehicleUsage.businessPersonal,
    updatedAt: DateTime.utc(2026, 7, 17, 12),
  );
}
