part of 'invoice_pdf_template_renderer.dart';

class InvoicePdfContentRules {
  const InvoicePdfContentRules._();

  static const missingLineItems = 'missing_line_items';
  static const blankLineItem = 'blank_line_item';
  static const missingInvoiceNumber = 'missing_invoice_number';
  static const missingCompanyName = 'missing_company_name';
  static const missingClientName = 'missing_client_name';
  static const dueDateBeforeIssueDate = 'due_date_before_issue_date';
  static const nonFiniteLineQuantity = 'non_finite_line_quantity';
  static const nonFiniteLineUnitPrice = 'non_finite_line_unit_price';
  static const nonFiniteLineTaxRate = 'non_finite_line_tax_rate';
  static const negativeLineTaxRate = 'negative_line_tax_rate';
  static const nonFiniteDiscountValue = 'non_finite_discount_value';
  static const negativeDiscountValue = 'negative_discount_value';
  static const excessiveDiscountPercent = 'excessive_discount_percent';
  static const excessiveDiscountAmount = 'excessive_discount_amount';
  static const nonFinitePaymentAmount = 'non_finite_payment_amount';

  static List<String> issueCodesForRecord(InvoiceRecord record) {
    final issues = <String>[];
    if (record.invoiceNumber.trim().isEmpty) issues.add(missingInvoiceNumber);
    if (record.company.bestName.trim().isEmpty) issues.add(missingCompanyName);
    if (record.client.bestName.trim().isEmpty) issues.add(missingClientName);
    final dueDate = record.dueDate;
    if (dueDate != null && dueDate.isBefore(record.issueDate)) {
      issues.add(dueDateBeforeIssueDate);
    }
    if (record.lines.isEmpty) issues.add(missingLineItems);
    if (record.lines.any(_isBlankLineItem)) issues.add(blankLineItem);
    for (final line in record.lines) {
      if (!line.quantity.isFinite) issues.add(nonFiniteLineQuantity);
      if (!line.unitPrice.isFinite) issues.add(nonFiniteLineUnitPrice);
      if (!line.taxRate.isFinite) issues.add(nonFiniteLineTaxRate);
      if (line.taxRate < 0) issues.add(negativeLineTaxRate);
    }
    _addDiscountIssues(record, issues);
    if (record.payments.any((payment) => !payment.amount.isFinite)) {
      issues.add(nonFinitePaymentAmount);
    }
    return issues.toSet().toList(growable: false);
  }

  static String messageFor(Iterable<String> issues) {
    final issueSet = issues.toSet();
    final missingIdentity =
        issueSet.contains(missingInvoiceNumber) ||
        issueSet.contains(missingCompanyName) ||
        issueSet.contains(missingClientName);
    final missingLines =
        issueSet.contains(missingLineItems) || issueSet.contains(blankLineItem);
    if (missingIdentity && missingLines) {
      return 'Add the missing invoice business details and confirmed line items before preparing the PDF.';
    }
    if (missingIdentity) {
      return 'Add the missing invoice business details before preparing the PDF.';
    }
    if (missingLines) {
      return 'Add confirmed invoice line items before preparing the PDF.';
    }
    if (issueSet.contains(dueDateBeforeIssueDate)) {
      return 'Check the invoice dates before preparing the PDF.';
    }
    return 'Check invoice amounts, taxes, discounts, and payments before preparing the PDF.';
  }

  static void _addDiscountIssues(InvoiceRecord record, List<String> issues) {
    if (!record.discount.value.isFinite) {
      issues.add(nonFiniteDiscountValue);
      return;
    }
    if (record.discount.value < 0) issues.add(negativeDiscountValue);
    if (record.discount.type == InvoiceDiscountType.percent &&
        record.discount.value > 100) {
      issues.add(excessiveDiscountPercent);
    }
    final lineSubtotalsAreFinite = record.lines.every(
      (line) => line.quantity.isFinite && line.unitPrice.isFinite,
    );
    if (record.discount.type == InvoiceDiscountType.amount &&
        lineSubtotalsAreFinite &&
        AppInvoiceMoney.cents(record.discount.value) >
            record.lines.fold(
              0,
              (sum, line) =>
                  sum +
                  AppInvoiceMoney.lineSubtotalCents(
                    quantity: line.quantity,
                    unitPrice: line.unitPrice,
                  ),
            )) {
      issues.add(excessiveDiscountAmount);
    }
  }

  static bool _isBlankLineItem(InvoiceLineItemRecord line) {
    return line.name.trim().isEmpty && line.details.trim().isEmpty;
  }
}
