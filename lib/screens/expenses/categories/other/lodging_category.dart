import 'package:flutter/material.dart';

import '../expense_category.dart';

const lodgingCategory = ExpenseCategoryDefinition(
  label: 'Lodging',
  category: 'Lodging',
  icon: ExpenseActionIcon.rentLease,
  gradient: [Color(0xFF7E57C2), Color(0xFF4527A0)],
  quickAction: false,
);
