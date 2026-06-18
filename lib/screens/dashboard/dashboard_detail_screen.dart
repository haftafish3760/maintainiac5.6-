import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/industrial_panel_surface.dart';

part 'dashboard_detail_data.dart';

enum DashboardDetailKind { fuel, pay, trips, expenses, profit }

class DashboardDetailScreen extends StatelessWidget {
  const DashboardDetailScreen({
    super.key,
    required this.kind,
    this.startsInAddMode = false,
  });

  final DashboardDetailKind kind;
  final bool startsInAddMode;

  @override
  Widget build(BuildContext context) {
    final data = _DetailData.forKind(kind);
    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        children: [
          AppScreenHeader(title: data.title),
          const SizedBox(height: 8),
          const GlobalOdometerHeader(),
          const SizedBox(height: 8),
          _DetailHeader(data: data, startsInAddMode: startsInAddMode),
          const SizedBox(height: 8),
          _QuickActionRow(data: data),
          const SizedBox(height: 8),
          if (kind == DashboardDetailKind.expenses) ...[
            _ExpenseCategoryPanel(data: data),
            const SizedBox(height: 8),
          ],
          _EntryListPanel(data: data),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.data, required this.startsInAddMode});

  final _DetailData data;
  final bool startsInAddMode;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: data.color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              Text(
                data.period,
                style: const TextStyle(
                  color: Color(0xFFCAD2D5),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (startsInAddMode) ...[
            const SizedBox(height: 7),
            const Text(
              'Add mode selected from dashboard.',
              style: TextStyle(
                color: Color(0xFFFFD166),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final metric in data.metrics) _MetricChip(metric: metric),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.data});

  final _DetailData data;

  @override
  Widget build(BuildContext context) {
    if (data.actions.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < data.actions.length; i++) ...[
          Expanded(child: _ActionButton(action: data.actions[i])),
          if (i != data.actions.length - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _ExpenseCategoryPanel extends StatelessWidget {
  const _ExpenseCategoryPanel({required this.data});

  final _DetailData data;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('Categories'),
          const SizedBox(height: 7),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 58,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            itemCount: data.categories.length,
            itemBuilder: (context, index) {
              return _CategoryTile(category: data.categories[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _EntryListPanel extends StatelessWidget {
  const _EntryListPanel({required this.data});

  final _DetailData data;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(data.listTitle),
          const SizedBox(height: 7),
          for (final entry in data.entries) _EntryRow(entry: entry),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final _EntryData entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: () => _openRecord(context),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
            decoration: BoxDecoration(
              color: const Color(0xFF141A1D),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF4F5A60)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    entry.day,
                    style: const TextStyle(
                      color: Color(0xFFE2E8EA),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2E8EA),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCAD2D5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.amount,
                  style: TextStyle(
                    color: entry.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRecord(BuildContext context) {
    Navigator.of(
      context,
    ).push(appNativeRoute<void>(context, _RecordDetailScreen(entry: entry)));
  }
}

class _RecordDetailScreen extends StatelessWidget {
  const _RecordDetailScreen({required this.entry});

  final _EntryData entry;

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        children: [
          AppScreenHeader(title: entry.title),
          const SizedBox(height: 8),
          const GlobalOdometerHeader(),
          const SizedBox(height: 8),
          IndustrialPanelSurface(
            dark: true,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelTitle(entry.title),
                const SizedBox(height: 9),
                _ReceiptPreview(entry: entry),
                const SizedBox(height: 9),
                for (final line in entry.lines) _ReceiptLine(line: line),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.entry});

  final _EntryData entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF101416), width: 1.2),
      ),
      child: Text(
        entry.receiptLabel,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF101416),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        line,
        style: const TextStyle(
          color: Color(0xFFE2E8EA),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF48545A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: metric.color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final _ActionData action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: () {},
        icon: Icon(action.icon, size: 18),
        label: FittedBox(child: Text(action.label)),
        style: FilledButton.styleFrom(
          backgroundColor: action.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final _CategoryData category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF141A1D),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF4F5A60)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 30,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            category.total,
            style: TextStyle(
              color: category.color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFFE2E8EA),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
