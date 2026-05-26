import 'package:flutter/material.dart';

import 'expense_category.dart';

const mealsCategory = ExpenseCategoryDefinition(
  label: 'Meals',
  category: 'Meals',
  icon: ExpenseActionIcon.meals,
  gradient: [Color(0xFFE05C3F), Color(0xFF7B211D)],
  assetPath: 'assets/expense_icons/business_meals.png',
);
