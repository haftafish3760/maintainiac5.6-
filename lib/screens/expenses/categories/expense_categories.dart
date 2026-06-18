export 'expense_category.dart';

import 'business_license_category.dart';
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
import 'utilities_category.dart';
import 'other/advertising_category.dart';
import 'other/background_checks_category.dart';
import 'other/car_accessories_category.dart';
import 'other/charging_fees_category.dart';
import 'other/cleaning_supplies_category.dart';
import 'other/commissions_category.dart';
import 'other/contract_labor_category.dart';
import 'other/delivery_bags_category.dart';
import 'other/dispatch_fees_category.dart';
import 'other/equipment_category.dart';
import 'other/equipment_rental_category.dart';
import 'other/fuel_additives_category.dart';
import 'other/home_office_category.dart';
import 'other/internet_category.dart';
import 'other/laundry_category.dart';
import 'other/licenses_category.dart';
import 'other/lodging_category.dart';
import 'other/medical_category.dart';
import 'other/office_supplies_category.dart';
import 'other/passenger_amenities_category.dart';
import 'other/permits_category.dart';
import 'other/platform_fees_category.dart';
import 'other/postage_category.dart';
import 'other/printing_category.dart';
import 'other/rent_category.dart';
import 'other/roadside_help_category.dart';
import 'other/safety_gear_category.dart';
import 'other/storage_category.dart';
import 'other/subscriptions_category.dart';
import 'other/tool_rental_category.dart';
import 'other/training_category.dart';
import 'other/travel_category.dart';
import 'other/uniforms_category.dart';
import 'other/vehicle_parts_category.dart';
import 'other/vehicle_supplies_category.dart';
import 'other/vehicle_wash_category.dart';
import 'other/waste_disposal_category.dart';

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
  advertisingCategory,
  backgroundChecksCategory,
  carAccessoriesCategory,
  chargingFeesCategory,
  cleaningSuppliesCategory,
  commissionsCategory,
  contractLaborCategory,
  deliveryBagsCategory,
  dispatchFeesCategory,
  equipmentCategory,
  equipmentRentalCategory,
  fuelAdditivesCategory,
  homeOfficeCategory,
  internetCategory,
  laundryCategory,
  licensesCategory,
  lodgingCategory,
  medicalCategory,
  officeSuppliesCategory,
  passengerAmenitiesCategory,
  permitsCategory,
  platformFeesCategory,
  postageCategory,
  printingCategory,
  rentCategory,
  roadsideHelpCategory,
  safetyGearCategory,
  storageCategory,
  subscriptionsCategory,
  toolRentalCategory,
  trainingCategory,
  travelCategory,
  uniformsCategory,
  utilitiesCategory,
  vehiclePartsCategory,
  vehicleSuppliesCategory,
  vehicleWashCategory,
  wasteDisposalCategory,
  businessLicenseCategory,
];
