import 'package:flutter/material.dart';

class WorkSupplyTrade {
  const WorkSupplyTrade({
    required this.name,
    required this.assetPath,
    required this.color,
    required this.groups,
  });

  final String name;
  final String assetPath;
  final Color color;
  final List<WorkSupplyGroup> groups;
}

class WorkSupplyGroup {
  const WorkSupplyGroup({
    required this.name,
    this.assetPath,
    this.materials = const [],
    this.items = const [],
  });

  final String name;
  final String? assetPath;
  final List<WorkSupplyMaterial> materials;
  final List<WorkSupplyItem> items;
}

class WorkSupplyMaterial {
  const WorkSupplyMaterial({required this.name, required this.items});

  final String name;
  final List<WorkSupplyItem> items;
}

class WorkSupplyItem {
  const WorkSupplyItem({
    required this.name,
    required this.trade,
    required this.group,
    required this.unit,
    this.assetPath,
    this.keywords = const [],
    this.purchaseUnits = const [],
    this.sizes = const [],
  });

  final String name;
  final String trade;
  final String group;
  final String unit;
  final String? assetPath;
  final List<String> keywords;
  final List<String> purchaseUnits;
  final List<String> sizes;

  String get path => '$trade / $group';
}
