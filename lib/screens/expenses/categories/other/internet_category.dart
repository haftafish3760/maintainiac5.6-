import 'package:flutter/material.dart';

import '../expense_category.dart';

const internetCategory = ExpenseCategoryDefinition(
  label: 'Internet',
  category: 'Internet',
  icon: ExpenseActionIcon.utilities,
  gradient: [Color(0xFF29B6F6), Color(0xFF0277BD)],
  quickAction: false,
);
