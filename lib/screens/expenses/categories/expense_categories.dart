export 'expense_category.dart';

import 'package:flutter/material.dart';

import 'cell_phone_category.dart';
import 'expense_category.dart';
import 'fuel_category.dart';
import 'insurance_category.dart';
import 'loan_lease_category.dart';
import 'maintenance_category.dart';
import 'meals_category.dart';
import 'parking_category.dart';
import 'registration_category.dart';
import 'repair_category.dart';
import 'supplies_category.dart';
import 'tolls_category.dart';
import 'tools_category.dart';

const defaultExpenseCategories = <ExpenseCategoryDefinition>[
  fuelCategory,
  repairCategory,
  maintenanceCategory,
  insuranceCategory,
  parkingCategory,
  tollsCategory,
  mealsCategory,
  toolsCategory,
  materialsCategory,
  cellPhoneCategory,
  registrationCategory,
  loanLeaseCategory,
];

const otherExpenseCategories = <ExpenseCategoryDefinition>[
  ExpenseCategoryDefinition(
    label: 'Advertising',
    category: 'Advertising',
    icon: ExpenseActionIcon.registration,
    gradient: [Color(0xFF29B6F6), Color(0xFF0277BD)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Background Checks',
    category: 'Background Checks',
    icon: ExpenseActionIcon.registration,
    gradient: [Color(0xFF78909C), Color(0xFF37474F)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Car Accessories',
    category: 'Car Accessories',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF607D8B), Color(0xFF263238)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Charging Fees',
    category: 'Charging Fees',
    icon: ExpenseActionIcon.fuel,
    gradient: [Color(0xFF26A69A), Color(0xFF00695C)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Cleaning Supplies',
    category: 'Cleaning Supplies',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF26A69A), Color(0xFF00695C)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Commissions',
    category: 'Commissions',
    icon: ExpenseActionIcon.rentLease,
    gradient: [Color(0xFF4CAF7A), Color(0xFF1D5A3E)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Contract Labor',
    category: 'Contract Labor',
    icon: ExpenseActionIcon.tools,
    gradient: [Color(0xFF398862), Color(0xFF174831)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Delivery Bags',
    category: 'Delivery Bags',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF8F6CEB), Color(0xFF472D85)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Dispatch Fees',
    category: 'Dispatch Fees',
    icon: ExpenseActionIcon.registration,
    gradient: [Color(0xFF5D6F78), Color(0xFF20292E)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Equipment',
    category: 'Equipment',
    icon: ExpenseActionIcon.tools,
    gradient: [Color(0xFF546A7B), Color(0xFF25313A)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Equipment Rental',
    category: 'Equipment Rental',
    icon: ExpenseActionIcon.tools,
    gradient: [Color(0xFF7A5A24), Color(0xFF3D2B12)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Fuel Additives',
    category: 'Fuel Additives',
    icon: ExpenseActionIcon.fuel,
    gradient: [Color(0xFF1E9AD6), Color(0xFF145C91)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Home Office',
    category: 'Home Office',
    icon: ExpenseActionIcon.rentLease,
    gradient: [Color(0xFF546EBC), Color(0xFF28346E)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Internet',
    category: 'Internet',
    icon: ExpenseActionIcon.utilities,
    gradient: [Color(0xFF29B6F6), Color(0xFF0277BD)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Laundry',
    category: 'Laundry',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF26A69A), Color(0xFF00695C)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Licenses',
    category: 'Licenses',
    icon: ExpenseActionIcon.registration,
    gradient: [Color(0xFF78909C), Color(0xFF37474F)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Lodging',
    category: 'Lodging',
    icon: ExpenseActionIcon.rentLease,
    gradient: [Color(0xFF7E57C2), Color(0xFF4527A0)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Medical',
    category: 'Medical',
    icon: ExpenseActionIcon.insurance,
    gradient: [Color(0xFF26A69A), Color(0xFF00695C)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Office Supplies',
    category: 'Office Supplies',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF8F6CEB), Color(0xFF472D85)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Passenger Amenities',
    category: 'Passenger Amenities',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF8F6CEB), Color(0xFF472D85)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Permits',
    category: 'Permits',
    icon: ExpenseActionIcon.registration,
    gradient: [Color(0xFF78909C), Color(0xFF37474F)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Platform Fees',
    category: 'Platform Fees',
    icon: ExpenseActionIcon.registration,
    gradient: [Color(0xFF546A7B), Color(0xFF25313A)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Postage',
    category: 'Postage',
    icon: ExpenseActionIcon.registration,
    gradient: [Color(0xFF78909C), Color(0xFF37474F)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Printing',
    category: 'Printing',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF8F6CEB), Color(0xFF472D85)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Rent',
    category: 'Rent',
    icon: ExpenseActionIcon.rentLease,
    gradient: [Color(0xFF4CAF7A), Color(0xFF1D5A3E)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Roadside Help',
    category: 'Roadside Help',
    icon: ExpenseActionIcon.repair,
    gradient: [Color(0xFFE0A72C), Color(0xFF7E4D16)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Safety Gear',
    category: 'Safety Gear',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF5C6BC0), Color(0xFF283593)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Storage',
    category: 'Storage',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF8F6CEB), Color(0xFF472D85)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Subscriptions',
    category: 'Subscriptions',
    icon: ExpenseActionIcon.utilities,
    gradient: [Color(0xFF546EBC), Color(0xFF28346E)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Tool Rental',
    category: 'Tool Rental',
    icon: ExpenseActionIcon.tools,
    gradient: [Color(0xFF398862), Color(0xFF174831)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Training',
    category: 'Training',
    icon: ExpenseActionIcon.registration,
    gradient: [Color(0xFF78909C), Color(0xFF37474F)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Travel',
    category: 'Travel',
    icon: ExpenseActionIcon.tolls,
    gradient: [Color(0xFF5D6F78), Color(0xFF20292E)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Uniforms',
    category: 'Uniforms',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF8F6CEB), Color(0xFF472D85)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Utilities',
    category: 'Utilities',
    icon: ExpenseActionIcon.utilities,
    gradient: [Color(0xFF546EBC), Color(0xFF28346E)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Vehicle Parts',
    category: 'Vehicle Parts',
    icon: ExpenseActionIcon.repair,
    gradient: [Color(0xFFE0A72C), Color(0xFF7E4D16)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Vehicle Supplies',
    category: 'Vehicle Supplies',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF8F6CEB), Color(0xFF472D85)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Vehicle Wash',
    category: 'Vehicle Wash',
    icon: ExpenseActionIcon.repair,
    gradient: [Color(0xFF26A69A), Color(0xFF00695C)],
    quickAction: false,
  ),
  ExpenseCategoryDefinition(
    label: 'Waste Disposal',
    category: 'Waste Disposal',
    icon: ExpenseActionIcon.supplies,
    gradient: [Color(0xFF607D8B), Color(0xFF263238)],
    quickAction: false,
  ),
];
