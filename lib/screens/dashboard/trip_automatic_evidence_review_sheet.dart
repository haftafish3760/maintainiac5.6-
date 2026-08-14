/// Review sheet for GPS App Assistant possible-drive evidence.
///
/// Owns only the Dashboard presentation and explicit accept/reject actions for
/// local evidence candidates. It does not create workdays, trips, mileage,
/// vehicle assignments, profiles, or classifications. Consumed from the active
/// workday Dashboard so users can see and decide about assistant evidence.
library;

import 'package:flutter/material.dart';

import '../../shared/trip_tracking/trip_automatic_evidence_candidate.dart';
import '../../shared/trip_tracking/trip_tracking_controller.dart';

Future<void> showTripAutomaticEvidenceReviewSheet(BuildContext context) async {
  final controller = TripTrackingScope.maybeOf(context);
  if (controller == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TripAutomaticEvidenceReviewSheet(controller: controller),
  );
}

class _TripAutomaticEvidenceReviewSheet extends StatelessWidget {
  const _TripAutomaticEvidenceReviewSheet({required this.controller});

  final TripTrackingController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final pending = controller.pendingAutomaticEvidenceCandidates;
          final approved = controller.automaticEvidenceCandidates
              .where(
                (item) =>
                    item.state ==
                    TripAutomaticEvidenceCandidateState
                        .approvedForEditableReview,
              )
              .toList(growable: false);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'App Assistant Review',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  'These are possible drives, not confirmed records. Review each one before it can be used in a workday or trip.',
                ),
                const SizedBox(height: 16),
                if (pending.isEmpty)
                  const _EmptyEvidenceReview()
                else
                  ...pending.map(
                    (candidate) => _CandidateCard(
                      candidate: candidate,
                      onDecide: (approved) => _decide(
                        context,
                        candidate: candidate,
                        approved: approved,
                      ),
                    ),
                  ),
                if (approved.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Kept for later review',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  ...approved.map(
                    (candidate) => ListTile(
                      leading: const Icon(Icons.pending_actions_outlined),
                      title: Text(_candidateTime(candidate)),
                      subtitle: const Text(
                        'No workday, trip, mileage, vehicle, profile, or classification has been confirmed.',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _decide(
    BuildContext context, {
    required TripAutomaticEvidenceCandidate candidate,
    required bool approved,
  }) async {
    try {
      await controller.decideAutomaticEvidenceCandidate(
        candidateId: candidate.id,
        expectedRevision: candidate.revision,
        approved: approved,
      );
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.onDecide});

  final TripAutomaticEvidenceCandidate candidate;
  final Future<void> Function(bool approved) onDecide;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF1D6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'POSSIBLE DRIVE — REVIEW NEEDED',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(_candidateTime(candidate)),
            Text('Evidence: ${candidate.evidenceSources.join(', ')}'),
            if (candidate.suggestedVehicleId != null)
              Text('Suggested vehicle: ${candidate.suggestedVehicleId}'),
            const SizedBox(height: 6),
            const Text(
              'Keeping this saves the evidence for later review. It does not create or confirm a trip or mileage.',
            ),
            if (candidate.requiresPaidEntitlementOnAcceptance) ...[
              const SizedBox(height: 6),
              const Text(
                'The included monthly allowance has been used. You can reject this evidence, but keeping it requires paid access.',
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => onDecide(false),
                  child: const Text('NOT A TRIP'),
                ),
                FilledButton(
                  onPressed: candidate.requiresPaidEntitlementOnAcceptance
                      ? null
                      : () => onDecide(true),
                  child: const Text('KEEP FOR LATER REVIEW'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyEvidenceReview extends StatelessWidget {
  const _EmptyEvidenceReview();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 28),
    child: Text(
      'No possible drives need your review right now. Manual tracking is always available.',
      textAlign: TextAlign.center,
    ),
  );
}

String _candidateTime(TripAutomaticEvidenceCandidate candidate) {
  return '${_clockText(candidate.evidenceStartedAtUtc)} – '
      '${_clockText(candidate.evidenceEndedAtUtc)}';
}

String _clockText(DateTime timestamp) {
  final local = timestamp.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
