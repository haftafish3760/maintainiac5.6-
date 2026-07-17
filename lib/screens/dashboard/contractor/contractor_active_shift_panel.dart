import 'package:flutter/material.dart';

import 'contractor_dashboard_tiles.dart';

class ContractorActiveShiftPanel extends StatelessWidget {
  const ContractorActiveShiftPanel({
    this.shiftTime = '00:00',
    this.milesToday = '0',
    this.currentJob = '1',
    this.liveOdometerLabel,
    super.key,
  });

  final String shiftTime;
  final String milesToday;
  final String currentJob;
  final String? liveOdometerLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF081A22),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF4DA3FF), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_rounded, color: Color(0xFF7CC7FF), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active Contractor Day',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Oak Street repair is active. Add stops, notes, expenses, receipts, materials, invoices, and payments from here.',
                style: TextStyle(
                  color: Color(0xFFE6F5FF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ContractorShiftReadout(
                      label: 'Shift Time',
                      value: shiftTime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ContractorShiftReadout(
                      label: 'Miles Today',
                      value: milesToday,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ContractorShiftReadout(
                      label: 'Current Job',
                      value: currentJob,
                    ),
                  ),
                ],
              ),
              if (liveOdometerLabel != null) ...[
                const SizedBox(height: 8),
                Text(
                  liveOdometerLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFBEE9FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
