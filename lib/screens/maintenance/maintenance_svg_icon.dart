import 'package:flutter/material.dart';

class MaintenanceSvgIcon extends StatelessWidget {
  const MaintenanceSvgIcon({super.key, required this.itemName, this.size = 42});

  final String itemName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      maintenanceIcon(itemName),
      size: size,
      color: const Color(0xFFE8ECEE),
    );
  }
}

IconData maintenanceIcon(String itemName) {
  final lower = itemName.toLowerCase();
  if (lower.contains('engine oil')) return Icons.oil_barrel_outlined;
  if (lower.contains('oil filter')) return Icons.filter_alt_outlined;
  if (lower.contains('transmission')) return Icons.settings_suggest_outlined;
  if (lower.contains('coolant')) return Icons.thermostat_outlined;
  if (lower.contains('brake fluid')) return Icons.opacity_rounded;
  if (lower.contains('brake pad')) return Icons.album_outlined;
  if (lower.contains('engine air filter')) return Icons.air_rounded;
  if (lower.contains('cabin air filter')) return Icons.air_rounded;
  if (lower.contains('spark')) return Icons.bolt_rounded;
  if (lower.contains('serpentine') || lower.contains('belt')) {
    return Icons.loop_rounded;
  }
  if (lower.contains('radiator hose')) return Icons.water_drop_outlined;
  if (lower.contains('heater hose')) return Icons.water_drop_outlined;
  if (lower.contains('wiper')) return Icons.cleaning_services_outlined;
  if (lower.contains('battery')) return Icons.battery_charging_full_rounded;
  if (lower.contains('power steering')) return Icons.adjust_rounded;
  if (lower.contains('differential')) return Icons.settings_outlined;
  if (lower.contains('fuel filter')) return Icons.local_gas_station_outlined;
  if (lower.contains('tire')) return Icons.tire_repair_outlined;
  if (lower.contains('washer')) return Icons.water_drop_outlined;
  if (lower.contains('key fob')) return Icons.vpn_key_outlined;
  if (lower.contains('registration')) return Icons.assignment_outlined;
  if (lower.contains('inspection')) return Icons.fact_check_outlined;
  return Icons.build_rounded;
}
