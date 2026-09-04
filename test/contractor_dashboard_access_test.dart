import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/contractor/contractor_dashboard_access.dart';
import 'package:maintaniac/screens/dashboard/contractor/contractor_dashboard_snapshot.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_store.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';

void main() {
  test(
    'technician dashboard access follows the active profile permissions',
    () {
      final access = ContractorDashboardAccess.fromProfile(
        UserProfileRecord(
          id: 'tech-7',
          name: 'Riley',
          type: UserProfileType.contractor,
          role: UserRole.technician,
          permissions: permissionsForRole(UserRole.technician),
        ),
      );

      expect(access.memberId, 'tech-7');
      expect(access.canStartOwnDay, isTrue);
      expect(access.canViewAssignedJobs, isTrue);
      expect(access.canViewAllJobs, isFalse);
      expect(access.canViewUnpaidInvoices, isFalse);
    },
  );

  test(
    'technician snapshot includes only jobs assigned to that technician',
    () {
      final now = DateTime(2026, 8, 20, 8);
      final jobs = MaintainiacJobController.memory(
        initialJobs: [
          MaintainiacJobRecord(
            id: 'assigned',
            name: 'Assigned service call',
            assignedMemberIds: const ['tech-7'],
            scheduledStart: now,
            createdAt: now,
            updatedAt: now,
          ),
          MaintainiacJobRecord(
            id: 'someone-else',
            name: 'Other technician job',
            assignedMemberIds: const ['tech-9'],
            scheduledStart: now,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      addTearDown(jobs.dispose);

      final snapshot = ContractorDashboardSnapshot.fromControllers(
        now: now,
        vehicleCount: 1,
        milesToday: 0,
        dayStarted: false,
        viewerMemberId: 'tech-7',
        includeAllJobs: false,
        includeReceiptReview: false,
        includeUnpaidInvoices: false,
        jobs: jobs,
      );

      expect(snapshot.jobsToday, hasLength(1));
      expect(snapshot.jobsToday.single.id, 'assigned');
      expect(snapshot.jobsToday.single.title, 'Assigned service call');
    },
  );
}
