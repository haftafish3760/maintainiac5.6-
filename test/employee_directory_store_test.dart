import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/profiles/employee_directory_models.dart';
import 'package:maintaniac/shared/profiles/employee_directory_store.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';

void main() {
  group('EmployeeDirectoryRecord', () {
    test('parses only an explicit non-negative currency rate', () {
      expect(employeePayRateCents('28.50'), 2850);
      expect(employeePayRateCents(r'$1,234.5'), 123450);
      expect(employeePayRateCents('25/hr'), isNull);
      expect(employeePayRateCents('-25'), isNull);
      expect(employeePayRateCents(''), isNull);
    });

    test('stores permissions and derives backend modules', () {
      final record = EmployeeDirectoryRecord.create(
        ownerProfileId: 'owner-1',
        name: 'Sam Tech',
        phone: '555-0100',
        email: 'SAM@EXAMPLE.COM',
        roleLabel: 'Technician - Customized',
        roleName: UserRole.technician.name,
        customizedRole: true,
        permissions: const {
          UserPermission.viewAssignedJobs,
          UserPermission.addOwnExpenses,
          UserPermission.uploadOwnReceipts,
          UserPermission.recordMileage,
          UserPermission.useMaterials,
        },
        allowedEmployeeRoleNames: const {'helper', 'driver'},
        allowedEmployeeRoleNamesByPermission: const {
          'expenses.fuel.team.edit': {'helper'},
          'expenses.fuel.team.view': {'helper', 'driver'},
        },
        allowedEmployeeIdsByPermission: const {
          'expenses.fuel.team.edit': {'employee-helper-1'},
        },
        allowedExpenseCategories: const {'fuel', 'materials'},
        payType: 'hourly',
        payFrequency: 'weekly',
        grossRate: '28.50',
        payPeriodAnchorDate: DateTime.utc(2026, 6, 15),
        now: DateTime.utc(2026, 6, 20, 12),
      );

      expect(record.status, EmployeeInviteStatus.readyToInvite);
      expect(record.email, 'sam@example.com');
      expect(record.allowedModules, containsAll(['jobs', 'expenses']));
      expect(record.allowedModules, containsAll(['mileage', 'inventory']));

      final restored = EmployeeDirectoryRecord.fromMap(record.toMap());
      expect(restored.permissions, record.permissions);
      expect(restored.allowedModules, record.allowedModules);
      expect(restored.allowedEmployeeRoleNames, {'helper', 'driver'});
      expect(restored.allowedEmployeeRoleNamesByPermission, {
        'expenses.fuel.team.edit': {'helper'},
        'expenses.fuel.team.view': {'helper', 'driver'},
      });
      expect(restored.allowedEmployeeIdsByPermission, {
        'expenses.fuel.team.edit': {'employee-helper-1'},
      });
      expect(restored.allowedExpenseCategories, {'fuel', 'materials'});
      expect(restored.payPeriodAnchorDate, DateTime.utc(2026, 6, 15));
      expect(
        restored.toInvitePayload()['permissions'],
        contains('useMaterials'),
      );
      expect(restored.toInvitePayload()['allowedExpenseCategories'], [
        'fuel',
        'materials',
      ]);
      expect(
        restored.toInvitePayload()['allowedEmployeeRoleNamesByPermission'],
        {
          'expenses.fuel.team.edit': ['helper'],
          'expenses.fuel.team.view': ['driver', 'helper'],
        },
      );
      expect(restored.toInvitePayload()['allowedEmployeeIdsByPermission'], {
        'expenses.fuel.team.edit': ['employee-helper-1'],
      });
    });
  });

  group('EmployeeDirectoryController', () {
    test('saves employee and queues invite locally', () async {
      final controller = EmployeeDirectoryController.memory();
      addTearDown(controller.dispose);
      final record = EmployeeDirectoryRecord.create(
        ownerProfileId: 'owner-1',
        name: 'Jordan Helper',
        phone: '',
        email: 'jordan@example.com',
        roleLabel: 'Helper',
        roleName: UserRole.helper.name,
        customizedRole: false,
        permissions: permissionsForRole(UserRole.helper),
        payType: 'hourly',
        payFrequency: 'weekly',
        grossRate: '18',
      );

      await controller.saveRecord(record);
      expect(controller.records.single.name, 'Jordan Helper');
      expect(controller.records.single.canQueueInvite, isTrue);

      await controller.queueInvite(record.id);
      expect(
        controller.records.single.status,
        EmployeeInviteStatus.inviteQueued,
      );
      expect(controller.pendingInvites.single.id, record.id);
    });
  });
}
