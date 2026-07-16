import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

import {
  assertEmulatorOnly,
  emulatorProjectId,
  firestoreHost,
  firestorePort,
} from './emulatorGuard.mjs';

let testEnv;

before(async () => {
  assertEmulatorOnly();
  testEnv = await initializeTestEnvironment({
    projectId: emulatorProjectId,
    firestore: {
      host: firestoreHost,
      port: firestorePort,
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedOrg();
});

after(async () => {
  await testEnv?.cleanup();
});

describe('Firestore rules emulator safety', () => {
  test('user can read self but cannot read another user', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'users/userA'), {
        uid: 'userA',
        name: 'User A',
      });
      await setDoc(doc(context.firestore(), 'users/userB'), {
        uid: 'userB',
        name: 'User B',
      });
    });

    const userA = dbFor('userA');

    await assertSucceeds(getDoc(doc(userA, 'users/userA')));
    await assertFails(getDoc(doc(userA, 'users/userB')));
  });

  test('clients cannot read or write account abuse counters', async () => {
    const owner = dbFor('ownerUid');

    await assertFails(getDoc(doc(owner, 'accountAbuseInstalls/installHash')));
    await assertFails(
      setDoc(doc(owner, 'accountAbuseInstalls/installHash'), {
        accountCount: 1,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'accountAbuseIpWindows/ipHash'), {
        accountCount: 1,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'accountCreationReviews/review1'), {
        reason: 'threshold',
      }),
    );
  });

  test('active members can read org, outsiders cannot', async () => {
    await assertSucceeds(getDoc(doc(dbFor('ownerUid'), 'orgs/orgA')));
    await assertSucceeds(getDoc(doc(dbFor('helperUid'), 'orgs/orgA')));
    await assertFails(getDoc(doc(dbFor('outsiderUid'), 'orgs/orgA')));
  });

  test('helper cannot read owner-only financial summaries', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'orgs/orgA/financialSummaries/day'), {
        total: 1000,
      });
    });

    await assertSucceeds(
      getDoc(doc(dbFor('ownerUid'), 'orgs/orgA/financialSummaries/day')),
    );
    await assertFails(
      getDoc(doc(dbFor('helperUid'), 'orgs/orgA/financialSummaries/day')),
    );
  });

  test('employee writes must keep createdByUid on themselves', async () => {
    const helper = dbFor('helperUid');

    await assertSucceeds(
      setDoc(doc(helper, 'orgs/orgA/expenses/expense1'), {
        createdByUid: 'helperUid',
        updatedByUid: 'helperUid',
        amount: 24,
      }),
    );
    await assertFails(
      setDoc(doc(helper, 'orgs/orgA/expenses/expense2'), {
        createdByUid: 'ownerUid',
        updatedByUid: 'helperUid',
        amount: 24,
      }),
    );
  });

  test('vehicles reject VIN and plate fields', async () => {
    const owner = dbFor('ownerUid');

    await assertSucceeds(
      setDoc(doc(owner, 'orgs/orgA/vehicles/truck1'), {
        nickname: 'Truck 1',
        type: 'truck',
        status: 'active',
        assignedMemberIds: ['ownerUid'],
        createdByUid: 'ownerUid',
        updatedByUid: 'ownerUid',
        createdAt: 1,
        updatedAt: 1,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/vehicles/truck2'), {
        nickname: 'Truck 2',
        vin: '1BADVINSHOULDNOTSAVE',
        assignedMemberIds: ['ownerUid'],
        createdByUid: 'ownerUid',
        updatedByUid: 'ownerUid',
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/vehicles/truck3'), {
        nickname: 'Truck 3',
        licensePlate: 'NOPE123',
        assignedMemberIds: ['ownerUid'],
        createdByUid: 'ownerUid',
        updatedByUid: 'ownerUid',
      }),
    );
  });

  test('mileage summaries are allowed but location-bearing mileage is denied', async () => {
    const owner = dbFor('ownerUid');
    const summary = mileageSummary({
      tripId: 'trip1',
      orgId: 'orgA',
      organizationSharingConsent: true,
      createdByUid: 'ownerUid',
      updatedByUid: 'ownerUid',
    });

    await assertSucceeds(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip1'), summary),
    );
    await assertSucceeds(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip1'), summary),
    );
    await assertFails(
      updateDoc(doc(owner, 'orgs/orgA/mileageRecords/trip1'), {
        acceptedMiles: 99.9,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip2'), {
        ...summary,
        latitude: 35.0,
        longitude: -80.0,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip3'), {
        ...summary,
        stopAddress: '123 Hidden Street',
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip4'), {
        ...summary,
        visibilityScope: 'location_tracking',
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip5'), {
        ...summary,
        altitude: 120,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip6'), {
        ...summary,
        orgId: 'another-org',
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip7'), {
        ...summary,
        organizationSharingConsent: false,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip8'), {
        ...summary,
        startingOdometer: -1,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip9'), {
        ...summary,
        estimatedEndingOdometer: 999,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/trip10'), {
        ...summary,
        acceptedSampleCount: 25,
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/otherTrip'), summary),
    );
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'orgs/orgA/mileageRecords/withheldTrip'),
        {
          ...summary,
          tripId: 'withheldTrip',
          createdByUid: 'anotherEmployee',
          updatedByUid: 'anotherEmployee',
          organizationSharingConsent: false,
        },
      );
    });
    await assertFails(
      getDoc(doc(owner, 'orgs/orgA/mileageRecords/withheldTrip')),
    );
  });

  test('a mileage recorder can read only their own company summaries', async () => {
    const owner = dbFor('ownerUid');
    const helper = dbFor('helperUid');
    const ownerSummary = mileageSummary({
      tripId: 'ownerTrip',
      orgId: 'orgA',
      organizationSharingConsent: true,
      createdByUid: 'ownerUid',
      updatedByUid: 'ownerUid',
    });
    const helperSummary = {
      ...ownerSummary,
      tripId: 'helperTrip',
      createdByUid: 'helperUid',
      updatedByUid: 'helperUid',
    };

    await assertSucceeds(
      setDoc(doc(owner, 'orgs/orgA/mileageRecords/ownerTrip'), ownerSummary),
    );
    await assertSucceeds(
      setDoc(doc(helper, 'orgs/orgA/mileageRecords/helperTrip'), helperSummary),
    );
    await assertSucceeds(
      getDoc(doc(helper, 'orgs/orgA/mileageRecords/helperTrip')),
    );
    await assertFails(
      getDoc(doc(helper, 'orgs/orgA/mileageRecords/ownerTrip')),
    );
  });

  test('solo users can access only their own mileage summaries', async () => {
    const owner = dbFor('ownerUid');
    const outsider = dbFor('outsiderUid');
    const summary = mileageSummary({
      tripId: 'soloTrip1',
      createdByUid: 'ownerUid',
      updatedByUid: 'ownerUid',
    });

    await assertSucceeds(
      setDoc(doc(owner, 'users/ownerUid/mileageRecords/soloTrip1'), summary),
    );
    await assertSucceeds(
      getDoc(doc(owner, 'users/ownerUid/mileageRecords/soloTrip1')),
    );
    await assertFails(
      updateDoc(doc(owner, 'users/ownerUid/mileageRecords/soloTrip1'), {
        acceptedMiles: 99.9,
      }),
    );
    await assertFails(
      getDoc(doc(outsider, 'users/ownerUid/mileageRecords/soloTrip1')),
    );
    await assertFails(
      setDoc(doc(owner, 'users/ownerUid/mileageRecords/soloTrip2'), {
        ...summary,
        routeSummary: 'hidden route details',
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'users/ownerUid/mileageRecords/soloTrip3'), {
        ...summary,
        orgId: 'orgA',
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'users/ownerUid/mileageRecords/soloTrip4'), {
        ...summary,
        organizationSharingConsent: true,
      }),
    );
  });

  test('jobs and generic records reject passenger and patient fields', async () => {
    const owner = dbFor('ownerUid');

    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/jobs/jobPatient'), {
        createdByUid: 'ownerUid',
        updatedByUid: 'ownerUid',
        assignedMemberIds: ['ownerUid'],
        patientName: 'Do Not Store',
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/records/transportRecord'), {
        createdByUid: 'ownerUid',
        updatedByUid: 'ownerUid',
        passengerName: 'Do Not Store',
      }),
    );
  });

  test('invite reads are limited to owner/admin or matching email', async () => {
    const owner = dbFor('ownerUid');
    const invited = dbFor('newEmployeeUid', { email: 'worker@example.com' });
    const wrongEmail = dbFor('wrongEmailUid', { email: 'other@example.com' });

    await assertSucceeds(
      setDoc(doc(owner, 'orgs/orgA/invites/invite1'), {
        orgId: 'orgA',
        email: 'worker@example.com',
        invitedByUid: 'ownerUid',
        status: 'pending',
      }),
    );
    await assertSucceeds(getDoc(doc(invited, 'orgs/orgA/invites/invite1')));
    await assertFails(getDoc(doc(wrongEmail, 'orgs/orgA/invites/invite1')));
  });

  test('upload grants and exports are server-created only', async () => {
    const owner = dbFor('ownerUid');

    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/uploadGrants/grant1'), {
        uid: 'ownerUid',
        status: 'open',
      }),
    );
    await assertFails(
      setDoc(doc(owner, 'orgs/orgA/exports/export1'), {
        uid: 'ownerUid',
        status: 'queued',
      }),
    );
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'orgs/orgA/uploadGrants/grant1'), {
        uid: 'ownerUid',
        status: 'open',
      });
    });
    await assertSucceeds(
      getDoc(doc(owner, 'orgs/orgA/uploadGrants/grant1')),
    );
    await assertFails(deleteDoc(doc(owner, 'orgs/orgA/uploadGrants/grant1')));
  });

  test('server-managed fields cannot be changed by clients', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'users/userA'), {
        uid: 'userA',
        plan: 'free',
      });
    });

    await assertFails(
      updateDoc(doc(dbFor('userA'), 'users/userA'), {
        uid: 'userA',
        plan: 'premium',
      }),
    );
  });
});

async function seedOrg() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'orgs/orgA'), {
      ownerUid: 'ownerUid',
      name: 'Maintainiac Test Org',
      syncEnabled: true,
    });
    await setDoc(doc(db, 'orgs/orgA/members/ownerUid'), {
      uid: 'ownerUid',
      orgId: 'orgA',
      status: 'active',
      role: 'owner',
      permissions: [
        'viewFinancials',
        'viewAuditLog',
        'viewAllExpenses',
        'manageVehicles',
        'editVehicleProfiles',
        'createJobs',
        'editJobs',
        'recordMileage',
        'viewFleetMileageReports',
        'editTeamMileage',
      ],
      allowedModules: ['expenses', 'admin', 'vehicles', 'jobs'],
    });
    await setDoc(doc(db, 'orgs/orgA/members/helperUid'), {
      uid: 'helperUid',
      orgId: 'orgA',
      status: 'active',
      role: 'helper',
      permissions: [
        'recordExpenses',
        'addOwnReceipts',
        'recordMileage',
        'editOwnMileage',
      ],
      allowedModules: ['expenses', 'receipts'],
    });
  });
}

function dbFor(uid, token = {}) {
  return testEnv.authenticatedContext(uid, token).firestore();
}

function mileageSummary(overrides = {}) {
  return {
    schema: 'trip_tracking_review_v1',
    tripId: 'trip1',
    createdByUid: 'ownerUid',
    updatedByUid: 'ownerUid',
    vehicleId: 'truck1',
    profile: 'roadVehicle',
    startedAt: '2026-07-16T12:00:00.000Z',
    finishedAt: '2026-07-16T12:45:00.000Z',
    createdAt: '2026-07-16T12:46:00.000Z',
    updatedAt: '2026-07-16T12:46:00.000Z',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1012,
    acceptedMeters: 19312.128,
    acceptedMiles: 12.0,
    walkingReviewSuggested: false,
    motionState: 'stopped',
    receivedSampleCount: 24,
    acceptedSampleCount: 18,
    locationDataIncluded: false,
    visibilityScope: 'mileage_only',
    ...overrides,
  };
}
