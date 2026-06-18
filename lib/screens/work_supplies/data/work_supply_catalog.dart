import 'package:flutter/material.dart';

import 'work_supply_item_identity_resolver.dart';
import 'work_supply_models.dart';

part 'catalog/plumbing/plumbing_catalog.dart';
part 'catalog/plumbing/fittings/copper.dart';
part 'catalog/plumbing/fittings/pvc_schedule_40.dart';
part 'catalog/plumbing/fittings/cpvc.dart';
part 'catalog/plumbing/fittings/pex.dart';
part 'catalog/plumbing/fittings/black_iron.dart';
part 'catalog/plumbing/fittings/galvanized_steel.dart';
part 'catalog/plumbing/fittings/brass.dart';
part 'catalog/plumbing/fittings/push_fit.dart';
part 'catalog/plumbing/fittings/cast_iron_and_no_hub.dart';
part 'catalog/plumbing/fittings/pvc_dwv.dart';
part 'catalog/plumbing/generated_plumbing_items.dart';
part 'catalog/plumbing/fittings/fittings_catalog.dart';
part 'catalog/plumbing/pipe_and_tubing/pipe_and_tubing_catalog.dart';
part 'catalog/plumbing/valves/valves_catalog.dart';
part 'catalog/plumbing/supply_lines/supply_lines_catalog.dart';
part 'catalog/plumbing/drainage_waste_vent/drainage_waste_vent_catalog.dart';
part 'catalog/plumbing/toilet_repair/toilet_repair_catalog.dart';
part 'catalog/plumbing/sink_and_faucet_repair/sink_and_faucet_repair_catalog.dart';
part 'catalog/plumbing/shower_and_tub_repair/shower_and_tub_repair_catalog.dart';
part 'catalog/plumbing/water_heater/water_heater_catalog.dart';
part 'catalog/plumbing/pumps/pumps_catalog.dart';
part 'catalog/plumbing/hangers_and_supports/hangers_and_supports_catalog.dart';
part 'catalog/plumbing/consumables/consumables_catalog.dart';
part 'catalog/electrical/electrical_catalog.dart';
part 'catalog/electrical/wire_and_cable/wire_and_cable_catalog.dart';
part 'catalog/electrical/breakers/breakers_catalog.dart';
part 'catalog/electrical/devices/devices_catalog.dart';
part 'catalog/electrical/boxes_and_covers/boxes_and_covers_catalog.dart';
part 'catalog/electrical/conduit_and_fittings/conduit_and_fittings_catalog.dart';
part 'catalog/electrical/connectors_and_consumables/connectors_and_consumables_catalog.dart';
part 'catalog/electrical/grounding_and_bonding/grounding_and_bonding_catalog.dart';
part 'catalog/electrical/panels_and_service_equipment/panels_and_service_equipment_catalog.dart';
part 'catalog/electrical/lighting/lighting_catalog.dart';
part 'catalog/hvac/hvac_catalog.dart';
part 'catalog/hvac/air_filters/air_filters_catalog.dart';
part 'catalog/hvac/controls_and_electrical/controls_and_electrical_catalog.dart';
part 'catalog/hvac/refrigerant_lines/refrigerant_lines_catalog.dart';
part 'catalog/hvac/ductwork_and_air_distribution/ductwork_and_air_distribution_catalog.dart';
part 'catalog/hvac/condensate/condensate_catalog.dart';
part 'catalog/hvac/tape_and_sealants/tape_and_sealants_catalog.dart';
part 'catalog/hvac/motors_and_blower_parts/motors_and_blower_parts_catalog.dart';
part 'catalog/hvac/ignition_and_gas_heat/ignition_and_gas_heat_catalog.dart';
part 'catalog/hvac/refrigerant_service/refrigerant_service_catalog.dart';
part 'catalog/carpentry/carpentry_catalog.dart';
part 'catalog/carpentry/lumber/lumber_catalog.dart';
part 'catalog/carpentry/sheet_goods/sheet_goods_catalog.dart';
part 'catalog/carpentry/fasteners/fasteners_catalog.dart';
part 'catalog/carpentry/trim_and_hardware/trim_and_hardware_catalog.dart';
part 'catalog/carpentry/connectors_and_framing_hardware/connectors_and_framing_hardware_catalog.dart';
part 'catalog/carpentry/adhesives_and_sealants/adhesives_and_sealants_catalog.dart';
part 'catalog/carpentry/decking_and_exterior_wood/decking_and_exterior_wood_catalog.dart';
part 'catalog/insulation/insulation_catalog.dart';
part 'catalog/insulation/batt_insulation/batt_insulation_catalog.dart';
part 'catalog/insulation/foam_and_air_sealing/foam_and_air_sealing_catalog.dart';
part 'catalog/insulation/blown_insulation/blown_insulation_catalog.dart';
part 'catalog/insulation/vapor_barriers_and_accessories/vapor_barriers_and_accessories_catalog.dart';
part 'catalog/drywall/drywall_catalog.dart';
part 'catalog/painting/painting_catalog.dart';
part 'catalog/drywall/panels_and_board/panels_and_board_catalog.dart';
part 'catalog/drywall/compound_and_mud/compound_and_mud_catalog.dart';
part 'catalog/drywall/tape_bead_and_trim/tape_bead_and_trim_catalog.dart';
part 'catalog/drywall/texture_and_patch/texture_and_patch_catalog.dart';
part 'catalog/drywall/fasteners_and_adhesives/fasteners_and_adhesives_catalog.dart';
part 'catalog/painting/paint/paint_catalog.dart';
part 'catalog/painting/paint_prep_and_supplies/paint_prep_and_supplies_catalog.dart';
part 'catalog/painting/caulk_and_patch/caulk_and_patch_catalog.dart';
part 'catalog/tile/tile_catalog.dart';
part 'catalog/tile/tile_materials/tile_materials_catalog.dart';
part 'catalog/tile/setting_materials/setting_materials_catalog.dart';
part 'catalog/tile/waterproofing/waterproofing_catalog.dart';
part 'catalog/tile/tools_and_accessories/tools_and_accessories_catalog.dart';
part 'catalog/roofing/roofing_catalog.dart';
part 'catalog/roofing/roof_covering/roof_covering_catalog.dart';
part 'catalog/roofing/flashing_and_sealants/flashing_and_sealants_catalog.dart';
part 'catalog/roofing/vents_and_roof_accessories/vents_and_roof_accessories_catalog.dart';
part 'catalog/roofing/gutters_and_drainage/gutters_and_drainage_catalog.dart';
part 'catalog/fencing/fencing_catalog.dart';
part 'catalog/masonry_concrete/masonry_concrete_catalog.dart';
part 'catalog/masonry_concrete/concrete/concrete_catalog.dart';
part 'catalog/masonry_concrete/masonry_materials/masonry_materials_catalog.dart';
part 'catalog/masonry_concrete/reinforcement_and_forms/reinforcement_and_forms_catalog.dart';
part 'catalog/masonry_concrete/anchors_and_repair/anchors_and_repair_catalog.dart';
part 'catalog/landscaping/landscaping_catalog.dart';
part 'catalog/landscaping/irrigation/irrigation_catalog.dart';
part 'catalog/landscaping/drainage_and_erosion/drainage_and_erosion_catalog.dart';
part 'catalog/landscaping/hardscape/hardscape_catalog.dart';
part 'catalog/low_voltage_data/low_voltage_data_catalog.dart';
part 'catalog/low_voltage_data/cable/cable_catalog.dart';
part 'catalog/low_voltage_data/terminations/terminations_catalog.dart';
part 'catalog/low_voltage_data/boxes_and_plates/boxes_and_plates_catalog.dart';
part 'catalog/low_voltage_data/testers_and_tools/testers_and_tools_catalog.dart';
part 'catalog/tools_safety/tools_safety_catalog.dart';
part 'catalog/tools_safety/tools/tools_catalog.dart';
part 'catalog/tools_safety/safety/safety_catalog.dart';
part 'catalog/tools_safety/measuring_and_layout/measuring_and_layout_catalog.dart';
part 'catalog/tools_safety/adhesives_and_general_consumables/adhesives_and_general_consumables_catalog.dart';

final workSupplyTrades = _hydrateTrades(<WorkSupplyTrade>[
  plumbingCatalog,
  electricalCatalog,
  hvacCatalog,
  carpentryCatalog,
  drywallCatalog,
  paintingCatalog,
  roofingCatalog,
  tileCatalog,
  insulationCatalog,
  fencingCatalog,
  masonryConcreteCatalog,
  landscapingCatalog,
  lowVoltageDataCatalog,
  toolsSafetyCatalog,
]);

final workSupplyCatalogItems = _dedupeWorkSupplyCatalogItems([
  for (final trade in workSupplyTrades)
    for (final category in trade.categories)
      for (final system in category.systems)
        for (final type in system.itemTypes) ...type.items,
]);

List<WorkSupplyItem> searchWorkSupplies(String query) {
  final tokens = query
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty && !_ignoredSearchToken(token))
      .toList();
  if (tokens.isEmpty) return workSupplyCatalogItems.take(25).toList();
  final scored = <({WorkSupplyItem item, int score})>[];
  for (final item in workSupplyCatalogItems) {
    final haystack = _normalizedSearchText(item.searchableText);
    var score = 0;
    for (final token in tokens) {
      if (_tokenAlternates(token).any(haystack.contains)) score++;
    }
    if (score == tokens.length) {
      if (_wantsHalfInch(tokens) && item.variant == '1/2 in') score += 10;
      if (_wantsThreeQuarter(tokens) && item.variant == '3/4 in') score += 10;
      if (_wantsQuarter(tokens) && item.variant == '1/4 in') score += 10;
      scored.add((item: item, score: score));
    }
  }
  scored.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    final aExpanded = _isExpandedCatalogItem(a.item);
    final bExpanded = _isExpandedCatalogItem(b.item);
    if (aExpanded != bExpanded) return aExpanded ? 1 : -1;
    return a.item.name.compareTo(b.item.name);
  });
  return scored.map((entry) => entry.item).take(50).toList();
}

bool _isExpandedCatalogItem(WorkSupplyItem item) {
  return item.itemType.contains('Expanded');
}

List<WorkSupplyItem> _dedupeWorkSupplyCatalogItems(List<WorkSupplyItem> items) {
  final byKey = <String, WorkSupplyItem>{};
  for (final item in items) {
    final key = tradeScopedWorkSupplyItemKey(item);
    final existing = byKey[key];
    if (existing == null || _isExpandedCatalogItem(existing)) {
      byKey[key] = item;
    }
  }
  return byKey.values.toList();
}

bool _wantsHalfInch(List<String> tokens) {
  return tokens.contains('half') || tokens.contains('1/2');
}

bool _wantsThreeQuarter(List<String> tokens) {
  return tokens.contains('3/4') ||
      (tokens.contains('three') && tokens.contains('quarter'));
}

bool _wantsQuarter(List<String> tokens) {
  return tokens.contains('quarter') || tokens.contains('1/4');
}

bool _ignoredSearchToken(String token) {
  return switch (token) {
    'a' || 'an' || 'the' || 'by' || 'x' => true,
    _ => false,
  };
}

String _normalizedSearchText(String text) {
  return text
      .replaceAll(' in ', ' inch ')
      .replaceAll(' in', ' inch')
      .replaceAll(' x ', ' ')
      .replaceAll('1/2', '1/2 half')
      .replaceAll('1/4', '1/4 quarter')
      .replaceAll('3/4', '3/4 three-quarter three quarter')
      .replaceAll('1-1/4', '1-1/4 inch and a quarter')
      .replaceAll('1-1/2', '1-1/2 inch and a half')
      .replaceAll('90', '90 ninety')
      .replaceAll('45', '45 forty-five forty five');
}

List<String> _tokenAlternates(String token) {
  return switch (token) {
    'half' => const ['half', '1/2'],
    'quarter' => const ['quarter', '1/4'],
    'three-quarter' => const ['three-quarter', '3/4'],
    'three' => const ['three'],
    'inch' => const ['inch', 'in'],
    'in' => const ['inch', 'in'],
    'ninety' => const ['ninety', '90'],
    'forty-five' => const ['forty-five', '45'],
    _ => [token],
  };
}

WorkSupplyTrade _trade(
  String name,
  Color color,
  List<WorkSupplyCategory> categories,
) {
  return WorkSupplyTrade(name: name, color: color, categories: categories);
}

WorkSupplyCategory _category(String name, List<WorkSupplySystem> systems) {
  return WorkSupplyCategory(name: name, systems: systems);
}

WorkSupplySystem _system(String name, List<WorkSupplyItemType> itemTypes) {
  return WorkSupplySystem(name: name, itemTypes: itemTypes);
}

WorkSupplyItemType _type(String name, List<WorkSupplyItem> items) {
  return WorkSupplyItemType(name: name, items: items);
}

List<WorkSupplyItem> _variants(
  String baseName,
  String unit,
  List<String> variants,
  List<String> aliases,
) {
  return [
    for (final variant in variants)
      WorkSupplyItem(
        id: '',
        name: '$variant $baseName',
        trade: '',
        category: '',
        system: '',
        itemType: '',
        variant: variant,
        unit: unit,
        aliases: aliases,
      ),
  ];
}

List<WorkSupplyTrade> _hydrateTrades(List<WorkSupplyTrade> trades) {
  var itemNumber = 0;
  return [
    for (final trade in trades)
      WorkSupplyTrade(
        name: trade.name,
        color: trade.color,
        categories: [
          for (final category in trade.categories)
            WorkSupplyCategory(
              name: category.name,
              systems: [
                for (final system in category.systems)
                  WorkSupplySystem(
                    name: system.name,
                    itemTypes: [
                      for (final type in system.itemTypes)
                        WorkSupplyItemType(
                          name: type.name,
                          items: [
                            for (final item in type.items)
                              WorkSupplyItem(
                                id: _sequentialItemId(++itemNumber),
                                name: item.name,
                                trade: trade.name,
                                category: category.name,
                                system: system.name,
                                itemType: type.name,
                                variant: item.variant,
                                unit: item.unit,
                                aliases: item.aliases,
                              ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
        ],
      ),
  ];
}

String _sequentialItemId(int value) {
  return 'MI-${value.toString().padLeft(3, '0')}';
}

const _supplySizes = [
  '1/4 in',
  '3/8 in',
  '1/2 in',
  '3/4 in',
  '1 in',
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
];
const _pipeSizes = [
  '1/2 in',
  '3/4 in',
  '1 in',
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
  '3 in',
  '4 in',
  '6 in',
  '8 in',
  '10 in',
  '12 in',
];
const _dwvSizes = [
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
  '3 in',
  '4 in',
  '6 in',
  '8 in',
  '10 in',
  '12 in',
];
const _threadedSizes = [
  '1/4 in',
  '3/8 in',
  '1/2 in',
  '3/4 in',
  '1 in',
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
  '2-1/2 in',
  '3 in',
  '4 in',
];
const _pushFitSizes = ['1/2 in', '3/4 in', '1 in'];
const _pushFitTeeSizes = [
  '1/2 x 1/2 x 1/2',
  '1/2 x 3/4 x 1/2',
  '3/4 x 1/2 x 1/2',
  '3/4 x 3/4 x 3/4',
  '3/4 x 3/4 x 1/2',
  '1 x 1 x 1/2',
  '1 x 1 x 3/4',
  '1 x 1 x 1',
];
const _teeSizes = [
  '1/2 x 1/2 x 1/2',
  '1/2 x 1/2 x 3/4',
  '1/2 x 3/4 x 1/2',
  '1/2 x 3/4 x 3/4',
  '3/4 x 3/4 x 3/4',
  '3/4 x 1/2 x 1/2',
  '3/4 x 3/4 x 1/2',
  '3/4 x 3/4 x 1',
  '3/4 x 1 x 3/4',
  '1 x 1 x 1',
  '1 x 1 x 1/2',
  '1 x 1 x 3/4',
  '1 x 3/4 x 1',
  '1 x 1-1/4 x 1',
  '1-1/4 x 1-1/4 x 1-1/4',
  '1-1/4 x 1-1/4 x 1',
  '1-1/4 x 1 x 1-1/4',
  '1-1/2 x 1-1/2 x 1-1/2',
  '1-1/2 x 1-1/2 x 1-1/4',
  '1-1/2 x 1-1/2 x 1',
  '2 x 2 x 1',
  '2 x 2 x 1-1/2',
  '2 x 2 x 2',
  '3 x 3 x 2',
  '3 x 3 x 3',
  '4 x 4 x 2',
  '4 x 4 x 3',
  '4 x 4 x 4',
];
const _reducerSizes = [
  '1/2 x 3/8',
  '3/4 x 1/2',
  '1 x 3/4',
  '1 x 1/2',
  '1-1/4 x 3/4',
  '1-1/4 x 1',
  '1-1/2 x 1',
  '1-1/2 x 1-1/4',
  '2 x 1',
  '2 x 1-1/4',
  '2 x 1-1/2',
  '3 x 1-1/2',
  '3 x 2',
  '4 x 2',
  '4 x 3',
];
const _dwvReducerSizes = [
  '1-1/2 x 1-1/4',
  '2 x 1-1/2',
  '3 x 1-1/2',
  '3 x 2',
  '4 x 2',
  '4 x 3',
  '6 x 4',
];
const _nippleSizes = [
  '1/4 x 2 in',
  '1/4 x 3 in',
  '3/8 x 2 in',
  '3/8 x 3 in',
  '1/2 x Close',
  '1/2 x 2 in',
  '1/2 x 3 in',
  '1/2 x 4 in',
  '1/2 x 6 in',
  '3/4 x Close',
  '3/4 x 2 in',
  '3/4 x 3 in',
  '3/4 x 4 in',
  '3/4 x 6 in',
  '1 x Close',
  '1 x 2 in',
  '1 x 3 in',
  '1 x 6 in',
  '1-1/4 x 3 in',
  '1-1/2 x 3 in',
  '2 x 3 in',
];
const _supplyPipe = [
  '1/4 in x 10 ft',
  '3/8 in x 10 ft',
  '1/2 in x 10 ft',
  '3/4 in x 10 ft',
  '1 in x 10 ft',
  '1-1/4 in x 10 ft',
  '1-1/2 in x 10 ft',
  '2 in x 10 ft',
];
const _pexRolls = [
  '3/8 in x 50 ft',
  '1/2 in x 50 ft',
  '1/2 in x 100 ft',
  '1/2 in x 300 ft',
  '3/4 in x 50 ft',
  '3/4 in x 100 ft',
  '3/4 in x 300 ft',
  '1 in x 100 ft',
];
const _tubularSizes = [
  '1-1/4 in',
  '1-1/2 in',
  '1-1/4 x 6 in',
  '1-1/4 x 12 in',
  '1-1/2 x 6 in',
  '1-1/2 x 12 in',
];
const _filterSizes = [
  '14 x 20 x 1',
  '14 x 25 x 1',
  '16 x 20 x 1',
  '16 x 25 x 1',
  '20 x 20 x 1',
  '20 x 25 x 1',
  '16 x 20 x 4',
  '20 x 25 x 4',
  '24 x 24 x 1',
];
