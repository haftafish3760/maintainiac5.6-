part of 'invoice_pdf_template_renderer.dart';

enum _InvoicePageRole { first, continuation, finalPage }

class _InvoicePageLines {
  const _InvoicePageLines({required this.role, required this.lines});

  final _InvoicePageRole role;
  final List<InvoiceLineItemRecord> lines;
}

class _InvoicePaginator {
  const _InvoicePaginator(this.record, {this.fixedLineCapacity});

  static const _firstPageLineCapacity = 7;
  static const _continuationPageLineCapacity = 12;
  static const _finalPageLineCapacity = 10;
  static const _minimumContinuationLines = 4;

  final InvoiceRecord record;
  final int? fixedLineCapacity;

  List<_InvoicePageLines> get pages {
    final lines = record.lines;
    final capacity = fixedLineCapacity;
    if (capacity != null) {
      return _fixedCapacityPages(lines, capacity);
    }
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

  List<_InvoicePageLines> _fixedCapacityPages(
    List<InvoiceLineItemRecord> lines,
    int capacity,
  ) {
    if (lines.length <= capacity) {
      return [
        _InvoicePageLines(role: _InvoicePageRole.finalPage, lines: lines),
      ];
    }
    final pages = <_InvoicePageLines>[];
    var index = 0;
    while (index < lines.length) {
      final next = (index + capacity).clamp(0, lines.length);
      final role = index == 0
          ? _InvoicePageRole.first
          : next == lines.length
          ? _InvoicePageRole.finalPage
          : _InvoicePageRole.continuation;
      pages.add(
        _InvoicePageLines(role: role, lines: lines.sublist(index, next)),
      );
      index = next;
    }
    return pages;
  }
}
