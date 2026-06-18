import 'package:flutter/material.dart';

import '../expense_category.dart';

const rentCategory = ExpenseCategoryDefinition(
  label: 'Rent',
  category: 'Rent',
  icon: ExpenseActionIcon.rentLease,
  gradient: [Color(0xFF4CAF7A), Color(0xFF1D5A3E)],
  quickAction: false,
);
