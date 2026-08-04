// Pre-workday Dashboard access to App Assistant review evidence.
//
// Owns only the compact review prompt and navigation to the existing evidence
// sheet. It does not create workdays, trips, stops, mileage, classifications,
// vehicle assignments, or profile assignments. Consumed by DashboardScreen.
import 'package:flutter/material.dart';

import '../../shared/trip_tracking/trip_tracking_controller.dart';
import 'trip_automatic_evidence_review_sheet.dart';

class TripAutomaticEvidencePreDayPrompt extends StatelessWidget {
  const TripAutomaticEvidencePreDayPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TripTrackingScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final count = controller.pendingAutomaticEvidenceCandidates.length;
        if (count == 0) return const SizedBox.shrink();
        final itemLabel = count == 1 ? 'possible drive' : 'possible drives';
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2114),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFB24A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.route_outlined, color: Color(0xFFFFC15C)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'App Assistant found $count $itemLabel to review. Nothing has been started or confirmed.',
                  style: const TextStyle(
                    color: Color(0xFFFFF0D2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => showTripAutomaticEvidenceReviewSheet(context),
                child: const Text('Review'),
              ),
            ],
          ),
        );
      },
    );
  }
}
