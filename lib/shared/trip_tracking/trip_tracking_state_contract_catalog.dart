import 'trip_tracking_models.dart';
import 'trip_tracking_state_machine.dart';

/// Auditable behavior contract for one canonical GPS-session lifecycle state.
///
/// Entry and exit sets come from the deterministic state machine so this
/// catalog cannot become a second transition authority.
class TripTrackingStateContract {
  const TripTrackingStateContract({
    required this.state,
    required this.definition,
    required this.persistenceRequirement,
    required this.recoveryBehavior,
    required this.userVisibleBehavior,
    required this.diagnosticEvent,
  });

  final TripTrackingSessionLifecycleContractState state;
  final String definition;
  final String persistenceRequirement;
  final String recoveryBehavior;
  final String userVisibleBehavior;
  final String diagnosticEvent;

  Set<TripTrackingSessionLifecycleContractState> get legalEntryStates =>
      Set.unmodifiable(
        TripTrackingSessionLifecycleContractState.values.where(
          (candidate) => TripTrackingSessionContractStateMachine.canTransition(
            candidate,
            state,
          ),
        ),
      );

  Set<TripTrackingSessionLifecycleContractState> get legalExitStates =>
      TripTrackingSessionContractStateMachine.allowedNextStates(state);

  Set<TripTrackingSessionLifecycleContractState> get forbiddenExitStates =>
      Set.unmodifiable(
        TripTrackingSessionLifecycleContractState.values.where(
          (candidate) => !legalExitStates.contains(candidate),
        ),
      );
}

abstract final class TripTrackingStateContractCatalog {
  static const bool odometerIsGlobalTruth = true;

  static List<TripTrackingStateContract> get all =>
      List.unmodifiable(_contracts.values);

  static TripTrackingStateContract forState(
    TripTrackingSessionLifecycleContractState state,
  ) => _contracts[state]!;

  static const _contracts =
      <TripTrackingSessionLifecycleContractState, TripTrackingStateContract>{
        TripTrackingSessionLifecycleContractState.IDLE:
            TripTrackingStateContract(
              state: TripTrackingSessionLifecycleContractState.IDLE,
              definition: 'No active or recoverable GPS session is running.',
              persistenceRequirement:
                  'Persist no active-session marker; retain history.',
              recoveryBehavior:
                  'Remain idle unless durable evidence requires review.',
              userVisibleBehavior: 'Show tracking as ready but not running.',
              diagnosticEvent: 'trip_state_idle',
            ),
        TripTrackingSessionLifecycleContractState
            .PREPARING: TripTrackingStateContract(
          state: TripTrackingSessionLifecycleContractState.PREPARING,
          definition:
              'A start request is validating identity, odometer, and storage.',
          persistenceRequirement:
              'Persist the start intent before native collection.',
          recoveryBehavior:
              'Resume validation or fail recoverably without duplicating.',
          userVisibleBehavior: 'Show that GPS assistance is preparing.',
          diagnosticEvent: 'trip_state_preparing',
        ),
        TripTrackingSessionLifecycleContractState
            .AWAITING_PERMISSION: TripTrackingStateContract(
          state: TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION,
          definition: 'Required location consent is not currently usable.',
          persistenceRequirement:
              'Persist the session and current permission state.',
          recoveryBehavior:
              'Recheck consent; never create a replacement session.',
          userVisibleBehavior:
              'Explain the missing permission and preserve manual use.',
          diagnosticEvent: 'trip_state_awaiting_permission',
        ),
        TripTrackingSessionLifecycleContractState.AWAITING_LOCATION_SERVICES:
            TripTrackingStateContract(
              state: TripTrackingSessionLifecycleContractState
                  .AWAITING_LOCATION_SERVICES,
              definition: 'Device location services are unavailable or off.',
              persistenceRequirement:
                  'Persist the session, boundary, and service state.',
              recoveryBehavior:
                  'Recheck services and continue only after validation.',
              userVisibleBehavior:
                  'Explain that GPS is unavailable without blocking TripLog.',
              diagnosticEvent: 'trip_state_awaiting_location_services',
            ),
        TripTrackingSessionLifecycleContractState
            .AWAITING_INITIAL_FIX: TripTrackingStateContract(
          state: TripTrackingSessionLifecycleContractState.AWAITING_INITIAL_FIX,
          definition:
              'The session exists but lacks a validated current location.',
          persistenceRequirement:
              'Persist true start time and provisional fix evidence.',
          recoveryBehavior:
              'Continue attempts without moving the trip start time.',
          userVisibleBehavior:
              'Show fix quality and allow location-degraded continuation.',
          diagnosticEvent: 'trip_state_awaiting_initial_fix',
        ),
        TripTrackingSessionLifecycleContractState
            .CANDIDATE_MOVEMENT: TripTrackingStateContract(
          state: TripTrackingSessionLifecycleContractState.CANDIDATE_MOVEMENT,
          definition:
              'Movement evidence may indicate a trip but is not confirmed.',
          persistenceRequirement:
              'Persist bounded candidate evidence without odometer claims.',
          recoveryBehavior:
              'Restore for review or expire only by an explicit rule.',
          userVisibleBehavior:
              'Offer start or review; never silently confirm a trip.',
          diagnosticEvent: 'trip_state_candidate_movement',
        ),
        TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING:
            TripTrackingStateContract(
              state: TripTrackingSessionLifecycleContractState.ACTIVE_TRACKING,
              definition:
                  'Validated GPS assistance is collecting advisory evidence.',
              persistenceRequirement:
                  'Checkpoint accepted distance, quality, and audit sequence.',
              recoveryBehavior:
                  'Restore the latest valid revision without double counting.',
              userVisibleBehavior:
                  'Show active assistance, quality, and user controls.',
              diagnosticEvent: 'trip_state_active_tracking',
            ),
        TripTrackingSessionLifecycleContractState
            .TEMPORARILY_STOPPED: TripTrackingStateContract(
          state: TripTrackingSessionLifecycleContractState.TEMPORARILY_STOPPED,
          definition: 'Motion is stationary but the trip remains active.',
          persistenceRequirement:
              'Persist stop evidence and the continuing trip boundary.',
          recoveryBehavior:
              'Restore the stop candidate without finalizing mileage.',
          userVisibleBehavior:
              'Show a stop advisory without declaring trip completion.',
          diagnosticEvent: 'trip_state_temporarily_stopped',
        ),
        TripTrackingSessionLifecycleContractState.PAUSED_BY_USER:
            TripTrackingStateContract(
              state: TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
              definition: 'The user intentionally suspended GPS assistance.',
              persistenceRequirement:
                  'Persist pause time, reason, distance, and last valid fix.',
              recoveryBehavior:
                  'Require user resume and create an explicit gap boundary.',
              userVisibleBehavior: 'Show paused state with resume and stop.',
              diagnosticEvent: 'trip_state_paused_by_user',
            ),
        TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM:
            TripTrackingStateContract(
              state: TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
              definition:
                  'A platform or safety condition stopped trusted collection.',
              persistenceRequirement:
                  'Persist the actionable cause and pre-pause evidence.',
              recoveryBehavior:
                  'Revalidate the cause and create a gap before resuming.',
              userVisibleBehavior:
                  'Explain the cause and preserve manual completion.',
              diagnosticEvent: 'trip_state_paused_by_system',
            ),
        TripTrackingSessionLifecycleContractState
            .SIGNAL_DEGRADED: TripTrackingStateContract(
          state: TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED,
          definition:
              'Location evidence continues with reduced trust or precision.',
          persistenceRequirement:
              'Persist quality history and rejected-distance evidence.',
          recoveryBehavior:
              'Validate recovery samples before trusted accumulation.',
          userVisibleBehavior:
              'Show low confidence without presenting precise truth.',
          diagnosticEvent: 'trip_state_signal_degraded',
        ),
        TripTrackingSessionLifecycleContractState.SIGNAL_LOST:
            TripTrackingStateContract(
              state: TripTrackingSessionLifecycleContractState.SIGNAL_LOST,
              definition: 'Usable location evidence is no longer arriving.',
              persistenceRequirement:
                  'Persist the last fix, gap start, and accepted distance.',
              recoveryBehavior:
                  'Open a signal gap and reject teleport reconstruction.',
              userVisibleBehavior:
                  'Show signal loss while keeping the trip recoverable.',
              diagnosticEvent: 'trip_state_signal_lost',
            ),
        TripTrackingSessionLifecycleContractState.RECOVERING:
            TripTrackingStateContract(
              state: TripTrackingSessionLifecycleContractState.RECOVERING,
              definition:
                  'Durable and native state are being reconciled idempotently.',
              persistenceRequirement:
                  'Preserve source revisions until recovery commits safely.',
              recoveryBehavior:
                  'Choose the highest valid committed revision exactly once.',
              userVisibleBehavior: 'Show recovery without inventing progress.',
              diagnosticEvent: 'trip_state_recovering',
            ),
        TripTrackingSessionLifecycleContractState
            .COMPLETION_PENDING: TripTrackingStateContract(
          state: TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
          definition:
              'GPS collection ended and TripLog confirmation is unfinished.',
          persistenceRequirement:
              'Persist the proposal, ending odometer draft, and audit.',
          recoveryBehavior:
              'Restore review without duplicating a TripLog proposal.',
          userVisibleBehavior:
              'Require review and user-confirmed ending mileage.',
          diagnosticEvent: 'trip_state_completion_pending',
        ),
        TripTrackingSessionLifecycleContractState.COMPLETED:
            TripTrackingStateContract(
              state: TripTrackingSessionLifecycleContractState.COMPLETED,
              definition: 'The approved completion workflow has finished.',
              persistenceRequirement:
                  'Retain confirmed history and immutable audit ancestry.',
              recoveryBehavior:
                  'Never resume or rewrite the completed session silently.',
              userVisibleBehavior: 'Show confirmed results and audit history.',
              diagnosticEvent: 'trip_state_completed',
            ),
        TripTrackingSessionLifecycleContractState.CANCELLED:
            TripTrackingStateContract(
              state: TripTrackingSessionLifecycleContractState.CANCELLED,
              definition:
                  'The user confirmed cancellation of an unfinished session.',
              persistenceRequirement:
                  'Retain cancelled evidence unless the user deletes it.',
              recoveryBehavior:
                  'Do not resume; retain cancellation evidence and ancestry.',
              userVisibleBehavior: 'Show cancellation and retained evidence.',
              diagnosticEvent: 'trip_state_cancelled',
            ),
        TripTrackingSessionLifecycleContractState
            .FAILED_RECOVERABLE: TripTrackingStateContract(
          state: TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE,
          definition:
              'Tracking failed but local evidence can still be recovered.',
          persistenceRequirement:
              'Persist evidence, failure cause, and last valid revision.',
          recoveryBehavior:
              'Retry idempotently or allow manual completion and review.',
          userVisibleBehavior:
              'Explain recovery choices without reporting zero-mile truth.',
          diagnosticEvent: 'trip_state_failed_recoverable',
        ),
        TripTrackingSessionLifecycleContractState
            .FAILED_UNRECOVERABLE: TripTrackingStateContract(
          state: TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
          definition: 'Trusted GPS continuation is unsafe for this session.',
          persistenceRequirement:
              'Preserve all readable evidence and the terminal cause.',
          recoveryBehavior:
              'Require fresh opt-in; retain manual TripLog completion.',
          userVisibleBehavior:
              'Explain GPS failure and preserve odometer entry controls.',
          diagnosticEvent: 'trip_state_failed_unrecoverable',
        ),
      };
}
