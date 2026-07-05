part of 'invoice_pdf_template_renderer.dart';

enum _InvoicePageRole { first, continuation, finalPage }

class _InvoicePageLines {
  const _InvoicePageLines({required this.role, required this.lines});

  final _InvoicePageRole role;
  final List<InvoiceLineItemRecord> lines;
}

class _InvoicePaginator {
  const _InvoicePaginator(this.record);

  static const _firstPageLineCapacity = 7;
  static const _continuationPageLineCapacity = 12;
  static const _finalPageLineCapacity = 10;
  static const _minimumContinuationLines = 4;

  final InvoiceRecord record;

  List<_InvoicePageLines> get pages {
    final lines = record.lines;
    if (lines.length <= _firstPageLineCapacity) {
      return [
        _InvoicePageLines(role: _InvoicePageRole.finalPage, lines: lines),
      ];
    }
    final pages = <_InvoicePageLines>[];
    var index = 0;
    pages.add(
      _InvoicePageLines(
        role: _InvoicePageRole.first,
        lines: lines.sublist(0, _firstPageLineCapacity),
      ),
    );
    index = _firstPageLineCapacity;
    while (lines.length - index > _finalPageLineCapacity) {
      final remaining = lines.length - index;
      final take =
          remaining <= _finalPageLineCapacity + _minimumContinuationLines
          ? (remaining / 2).floor()
          : (remaining - _finalPageLineCapacity).clamp(
              _minimumContinuationLines,
              _continuationPageLineCapacity,
            );
      pages.add(
        _InvoicePageLines(
          role: _InvoicePageRole.continuation,
          lines: lines.sublist(index, index + take),
        ),
      );
      index += take;
    }
    pages.add(
      _InvoicePageLines(
        role: _InvoicePageRole.finalPage,
        lines: lines.sublist(index),
      ),
    );
    return pages;
  }
}
