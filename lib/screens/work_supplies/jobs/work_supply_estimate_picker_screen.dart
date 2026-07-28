import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../invoices/data/invoice_record.dart';

class WorkSupplyEstimatePickerScreen extends StatelessWidget {
  const WorkSupplyEstimatePickerScreen({super.key, required this.estimates});

  final List<InvoiceRecord> estimates;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Import Estimate'),
            Expanded(
              child: estimates.isEmpty
                  ? const _NoEstimates()
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: estimates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final estimate = estimates[index];
                        return _EstimateCard(
                          estimate: estimate,
                          onTap: () => Navigator.of(context).pop(estimate),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoEstimates extends StatelessWidget {
  const _NoEstimates();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No saved estimates are available yet. Create an estimate in Invoices, Estimates & Payments, or create a direct job.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFC7D0D4), height: 1.4),
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.estimate, required this.onTap});

  final InvoiceRecord estimate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF172126),
      child: ListTile(
        onTap: onTap,
        title: Text(
          estimate.displayTitle,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${estimate.invoiceNumber} • ${estimate.status.name} • ${estimate.lines.length} line items',
          style: const TextStyle(color: Color(0xFFC7D0D4)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${estimate.total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF8FD3FF),
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Review & import',
              style: TextStyle(color: Color(0xFF55D68A), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
