import 'package:flutter/material.dart';

import '../expense_category.dart';

const storageCategory = ExpenseCategoryDefinition(
  label: 'Storage',
  category: 'Storage',
  icon: ExpenseActionIcon.supplies,
  gradient: [Color(0xFF8F6CEB), Color(0xFF472D85)],
  quickAction: false,
);
