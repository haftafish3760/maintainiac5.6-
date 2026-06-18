import 'package:flutter/material.dart';

import '../expense_category.dart';

const laundryCategory = ExpenseCategoryDefinition(
  label: 'Laundry',
  category: 'Laundry',
  icon: ExpenseActionIcon.supplies,
  gradient: [Color(0xFF26A69A), Color(0xFF00695C)],
  quickAction: false,
);
