import 'package:flutter/material.dart';

import '../expense_category.dart';

const travelCategory = ExpenseCategoryDefinition(
  label: 'Travel',
  category: 'Travel',
  icon: ExpenseActionIcon.tolls,
  gradient: [Color(0xFF5D6F78), Color(0xFF20292E)],
  quickAction: false,
);
