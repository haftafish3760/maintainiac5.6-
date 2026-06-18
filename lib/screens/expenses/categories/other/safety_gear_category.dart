import 'package:flutter/material.dart';

import '../expense_category.dart';

const safetyGearCategory = ExpenseCategoryDefinition(
  label: 'Safety Gear',
  category: 'Safety Gear',
  icon: ExpenseActionIcon.supplies,
  gradient: [Color(0xFF5C6BC0), Color(0xFF283593)],
  quickAction: false,
);
