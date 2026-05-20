import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MaintenanceSvgIcon extends StatelessWidget {
  const MaintenanceSvgIcon({super.key, required this.itemName, this.size = 42});

  final String itemName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      maintenanceSvgAsset(itemName),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

String maintenanceSvgAsset(String itemName) {
  final lower = itemName.toLowerCase();
  if (lower.contains('engine oil')) return _asset('engine_oil');
  if (lower.contains('oil filter')) return _asset('oil_filter');
  if (lower.contains('transmission')) return _asset('transmission_fluid');
  if (lower.contains('coolant')) return _asset('coolant');
  if (lower.contains('brake fluid')) return _asset('brake_fluid');
  if (lower.contains('brake pad')) return _asset('brake_pads');
  if (lower.contains('engine air filter')) return _asset('engine_air_filter');
  if (lower.contains('cabin air filter')) return _asset('cabin_air_filter');
  if (lower.contains('spark')) return _asset('spark_plugs');
  if (lower.contains('serpentine') || lower.contains('belt')) {
    return _asset('serpentine_belt');
  }
  if (lower.contains('radiator hose')) return _asset('radiator_hose');
  if (lower.contains('heater hose')) return _asset('heater_hose');
  if (lower.contains('wiper')) return _asset('wiper_blades');
  if (lower.contains('battery')) return _asset('battery');
  if (lower.contains('power steering')) return _asset('power_steering_fluid');
  if (lower.contains('differential')) return _asset('differential_fluid');
  if (lower.contains('fuel filter')) return _asset('fuel_filter');
  if (lower.contains('tire')) return _asset('tires');
  if (lower.contains('washer')) return _asset('washer_fluid');
  if (lower.contains('key fob')) return _asset('key_fob_battery');
  if (lower.contains('registration')) return _asset('registration');
  if (lower.contains('inspection')) return _asset('inspection');
  return _asset('generic');
}

String _asset(String name) => 'assets/maintenance_icons/$name.svg';
