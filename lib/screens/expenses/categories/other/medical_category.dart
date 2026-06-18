import 'package:flutter/material.dart';

import '../expense_category.dart';

const medicalCategory = ExpenseCategoryDefinition(
  label: 'Medical',
  category: 'Medical',
  icon: ExpenseActionIcon.insurance,
  gradient: [Color(0xFF26A69A), Color(0xFF00695C)],
  quickAction: false,
);
