import 'package:flutter/material.dart';

import 'expense_category.dart';

const businessLicenseCategory = ExpenseCategoryDefinition(
  label: 'License',
  category: 'Business License',
  icon: ExpenseActionIcon.registration,
  gradient: [Color(0xFF78909C), Color(0xFF37474F)],
  assetPath: 'assets/expense_icons/business_license.png',
);
