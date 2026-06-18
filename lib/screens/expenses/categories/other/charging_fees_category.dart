import 'package:flutter/material.dart';

import '../expense_category.dart';

const chargingFeesCategory = ExpenseCategoryDefinition(
  label: 'Charging Fees',
  category: 'Charging Fees',
  icon: ExpenseActionIcon.fuel,
  gradient: [Color(0xFF26A69A), Color(0xFF00695C)],
  quickAction: false,
);
