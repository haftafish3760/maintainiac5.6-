import 'package:flutter/material.dart';

import 'data/active_workday_odometer_review.dart';

/// Compact Active Day visibility and read-only review for odometer exceptions.
///
/// Owns presentation of saved lower-reading evidence. Does not resolve a
/// correction, alter an odometer, end a workday, or create a TripLog record.
/// Consumed by ActiveWorkdayScreen after a lower End Day reading is reviewed.
class ActiveWorkdayOdometerReviewNotice extends StatelessWidget {
  const ActiveWorkdayOdometerReviewNotice({
    super.key,
    required this.reviews,
    required this.onPressed,
  });

  final List<ActiveWorkdayOdometerReview> reviews;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();
    final count = reviews.length;
    return Semantics(
      button: true,
      label: '$count odometer ${count == 1 ? 'review' : 'reviews'} pending',
      child: Material(
        color: const Color(0xFF2B2416),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFC857)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fact_check_rounded,
                  color: Color(0xFFFFD27A),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    count == 1
                        ? 'ODOMETER REVIEW PENDING'
                        : '$count ODOMETER REVIEWS PENDING',
                    style: const TextStyle(
                      color: Color(0xFFFFE0A3),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFFE0A3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showActiveWorkdayOdometerReviews(
  BuildContext context, {
  required List<ActiveWorkdayOdometerReview> reviews,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF101719),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Odometer reviews',
              style: TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your workday remains open. These entries did not change the vehicle odometer, mileage, or TripLog.',
              style: TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            ...reviews.map(_ReviewRow.new),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Keep workday open'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.review);

  final ActiveWorkdayOdometerReview review;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF1B2427),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF526168)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          review.reason.label,
          style: const TextStyle(
            color: Color(0xFFF0F4F2),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Entered ${review.enteredOdometer} mi · active start ${review.startingOdometer} mi · ${review.differenceMiles} mi difference',
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}
