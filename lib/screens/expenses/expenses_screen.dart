import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../work_supplies/work_supply_receipt_screen.dart';
import 'categories/expense_categories.dart';
import 'expense_calendar.dart';
import 'expense_entry_screen.dart';
import 'expense_reminder_screen.dart';
import 'expense_settings_screen.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.expenses,
      floatingActionButton: const _ExpenseFab(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        children: const [
          GlobalOdometerHeader(section: AppSection.expenses),
          SizedBox(height: 10),
          _ExpenseTotalsRow(),
          SizedBox(height: 10),
          _ExpenseMessageCenter(),
          SizedBox(height: 10),
          _TopThreeExpenseStrip(),
          SizedBox(height: 12),
          _ExpenseQuickActions(),
          SizedBox(height: 14),
          ExpenseMonthCalendar(),
        ],
      ),
    );
  }
}

class _ExpenseTotalsRow extends StatelessWidget {
  const _ExpenseTotalsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _ExpenseTotalCard(title: 'Weekly Total', value: r'$0.00'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _ExpenseTotalCard(title: 'Monthly Total', value: r'$0.00'),
        ),
      ],
    );
  }
}

class _ExpenseTotalCard extends StatelessWidget {
  const _ExpenseTotalCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF171D20), Color(0xFF080B0D)],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF66737A), width: 1.1),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 7, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD4DDE1),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseMessageCenter extends StatelessWidget {
  const _ExpenseMessageCenter();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF171D0F), Color(0xFF050806)],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF2B3524), width: 1.1),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.notifications_active_rounded,
            color: Color(0xFFFFD166),
            size: 24,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '0 messages, 0 drafts, 0 reminders',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopThreeExpenseStrip extends StatelessWidget {
  const _TopThreeExpenseStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _TopExpenseCard(label: 'Fuel', color: Color(0xFF1E9AD6)),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _TopExpenseCard(label: 'Food', color: Color(0xFFE05C3F)),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _TopExpenseCard(
            label: 'Work Supplies',
            color: Color(0xFF398862),
          ),
        ),
      ],
    );
  }
}

class _TopExpenseCard extends StatelessWidget {
  const _TopExpenseCard({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color, width: 1.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          const _TopExpenseLine(label: 'Business', value: r'$0.00'),
          const SizedBox(height: 3),
          const _TopExpenseLine(label: 'Personal', value: r'$0.00'),
        ],
      ),
    );
  }
}

class _TopExpenseLine extends StatelessWidget {
  const _TopExpenseLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD4DDE1),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ExpenseQuickActions extends StatelessWidget {
  const _ExpenseQuickActions();

  @override
  Widget build(BuildContext context) {
    final categories = defaultExpenseCategories;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121719),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF66737A), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  tooltip: 'Expense quick action settings',
                  onPressed: () => Navigator.of(context).push(
                    appNativeRoute<void>(
                      context,
                      const ExpenseSettingsScreen(),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: Color(0xFFFFD166),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 420 ? 4 : 3;
              final width =
                  (constraints.maxWidth - ((columns - 1) * 8)) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final category in categories)
                    SizedBox(
                      width: width,
                      child: _ExpenseActionButton(category: category),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExpenseActionButton extends StatelessWidget {
  const _ExpenseActionButton({required this.category});

  final ExpenseCategoryDefinition category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: InkWell(
        onTap: () => _openCategory(context),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: category.gradient,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: .20)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: _ExpenseActionImage(category: category),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 28,
              child: Text(
                category.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategory(BuildContext context) {
    if (category.category == 'Reminder') {
      Navigator.of(
        context,
      ).push(appNativeRoute<void>(context, const ExpenseReminderScreen()));
      return;
    }
    if (category.category == 'Materials') {
      Navigator.of(
        context,
      ).push(appNativeRoute<void>(context, const WorkSupplyReceiptScreen()));
      return;
    }
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        ExpenseEntryScreen(category: category.category),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1F2528),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                category.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _OptionButton(
                      label: 'Move',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionButton(
                      label: 'Info',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _OptionButton(
                      label: 'Remove',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseActionImage extends StatelessWidget {
  const _ExpenseActionImage({required this.category});

  final ExpenseCategoryDefinition category;

  @override
  Widget build(BuildContext context) {
    final path = category.assetPath;
    if (path != null) {
      return Image.asset(path, fit: BoxFit.contain);
    }
    return Icon(
      _fallbackIcon(category.icon),
      color: const Color(0xFF071014),
      size: 31,
    );
  }

  IconData _fallbackIcon(ExpenseActionIcon icon) {
    return switch (icon) {
      ExpenseActionIcon.fuel => Icons.local_gas_station_rounded,
      ExpenseActionIcon.repair => Icons.build_rounded,
      ExpenseActionIcon.insurance => Icons.verified_user_rounded,
      ExpenseActionIcon.parking => Icons.local_parking_rounded,
      ExpenseActionIcon.tolls => Icons.toll_rounded,
      ExpenseActionIcon.meals => Icons.restaurant_rounded,
      ExpenseActionIcon.tools => Icons.handyman_rounded,
      ExpenseActionIcon.supplies => Icons.inventory_2_rounded,
      ExpenseActionIcon.registration => Icons.badge_rounded,
      ExpenseActionIcon.reminder => Icons.notifications_rounded,
      ExpenseActionIcon.rentLease => Icons.payments_rounded,
      ExpenseActionIcon.utilities => Icons.power_rounded,
    };
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121719),
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF66737A), width: 1.1),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseFab extends StatelessWidget {
  const _ExpenseFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF28A745),
      foregroundColor: Colors.white,
      onPressed: () => _showCategoryPicker(context),
      child: const Icon(Icons.add_rounded, size: 32),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2528),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: .45,
          initialChildSize: .82,
          maxChildSize: .92,
          builder: (context, controller) =>
              _ExpenseCategoryPicker(scrollController: controller),
        );
      },
    );
  }
}

class _ExpenseCategoryPicker extends StatelessWidget {
  const _ExpenseCategoryPicker({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: const [
        _PickerTitle('Quick Expense Buttons'),
        SizedBox(height: 8),
        _PickerGrid(categories: defaultExpenseCategories),
        SizedBox(height: 14),
        _PickerTitle('Other Categories'),
        SizedBox(height: 8),
        _PickerGrid(categories: otherExpenseCategories),
      ],
    );
  }
}

class _PickerTitle extends StatelessWidget {
  const _PickerTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFE8ECEE),
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PickerGrid extends StatelessWidget {
  const _PickerGrid({required this.categories});

  final List<ExpenseCategoryDefinition> categories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 4 : 3;
        final width = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: _ExpenseActionButton(category: category),
              ),
          ],
        );
      },
    );
  }
}
