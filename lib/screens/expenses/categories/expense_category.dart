import 'package:flutter/material.dart';

enum ExpenseActionIcon {
  fuel,
  repair,
  insurance,
  parking,
  tolls,
  meals,
  tools,
  supplies,
  registration,
  reminder,
  rentLease,
  utilities,
}

class ExpenseCategoryDefinition {
  const ExpenseCategoryDefinition({
    required this.label,
    required this.category,
    required this.icon,
    required this.gradient,
    this.assetPath,
    this.quickAction = true,
  });

  final String label;
  final String category;
  final ExpenseActionIcon icon;
  final List<Color> gradient;
  final String? assetPath;
  final bool quickAction;
}
