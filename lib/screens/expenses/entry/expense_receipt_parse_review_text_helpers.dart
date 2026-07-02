part of 'expense_receipt_entry_screen.dart';

String _joinReceiptReviewSentences(Iterable<String?> sentences) {
  final safeSentences = [
    for (final sentence in sentences)
      if ((sentence ?? '').trim().isNotEmpty) sentence!.trim(),
  ];
  return safeSentences.join(' ');
}
