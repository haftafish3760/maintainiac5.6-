part of '../../work_supply_receipt_parser.dart';

/// Resolves unambiguous HVAC receipt wording before broad cross-trade rules.
///
/// The normal candidate scorer remains the fallback. These rules only protect
/// exact HVAC service stock whose receipt wording carries higher information
/// than a generic electrical, plumbing, or broad catalog alias.
WorkSupplyItem? _directHvacReceiptPrecedenceMatch(
  String text, {
  String? tradeScope,
}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'hvac') {
    return null;
  }

  WorkSupplyItem? findHvac(bool Function(String name) matches) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && matches(name)) return item;
    }
    return null;
  }

  final capacitor = RegExp(r'\b(\d+(?:\.\d+)?/\d+)\b').firstMatch(text);
  if (capacitor != null &&
      RegExp(r'\b(dual\s*run|run\s*cap|capacitor|cap)\b').hasMatch(text)) {
    final wantsRatedDualRunCapacitor =
        RegExp(r'\b(370|440)\s*v\b').hasMatch(text) &&
        RegExp(r'\bdual\s*run\b').hasMatch(text);
    final match = findHvac(
      (name) => wantsRatedDualRunCapacitor
          ? name.contains('${capacitor.group(1)} mfd') &&
                name.contains('dual run capacitor')
          : name == '${capacitor.group(1)} mfd run capacitor',
    );
    if (match != null) return match;
  }

  final wantsContactor = RegExp(r'\bcontactor\b').hasMatch(text);
  if (wantsContactor) {
    final amps = RegExp(
      r'\b(20|30|40|50|60)\s*(?:a|amp)\b',
    ).firstMatch(text)?.group(1);
    final match = findHvac(
      (name) =>
          name.contains('contactor') &&
          (amps == null || name.contains('$amps amp')),
    );
    if (match != null) return match;
  }

  final thermostatWire =
      RegExp(r'\b(stat|tstat|thermostat|termostato)\b').hasMatch(text) &&
      RegExp(r'\b(wire|cable)\b').hasMatch(text);
  if (thermostatWire) {
    final gauge = RegExp(r'\b(18)[-/](2|5|8)\b').firstMatch(text);
    final match = findHvac(
      (name) =>
          name.contains('thermostat wire') &&
          (gauge == null ||
              name.contains('${gauge.group(1)}/${gauge.group(2)}')),
    );
    if (match != null) return match;
  }

  final wantsDualPortPressureSwitch =
      RegExp(r'\bdual\s*port\b').hasMatch(text) &&
      RegExp(r'\bpressure\s*switch\b').hasMatch(text);
  if (wantsDualPortPressureSwitch) {
    final match = findHvac(
      (name) => name.contains('dual port') && name.contains('pressure switch'),
    );
    if (match != null) return match;
  }

  final matrix = _receiptSizeMatrix(text);
  final wantsMediaCabinetFilter =
      RegExp(r'\bmedia\s*cabinet\b').hasMatch(text) &&
      RegExp(r'\bfilter\b').hasMatch(text);
  if (wantsMediaCabinetFilter) {
    final merv = RegExp(r'\bmerv\s*(8|11|13|16)\b').firstMatch(text)?.group(1);
    final match = findHvac(
      (name) =>
          name.contains('media cabinet') &&
          (merv == null || name.contains('merv $merv')) &&
          (matrix == null || name.contains(matrix)),
    );
    if (match != null) return match;
  }

  final wantsPleatedFilter =
      RegExp(r'\b(furnace|return|air|ac)\b').hasMatch(text) &&
      RegExp(r'\bfilter\b').hasMatch(text) &&
      !wantsMediaCabinetFilter &&
      !RegExp(
        r'\b(filter\s*rack|return\s*(?:filter\s*)?grille)\b',
      ).hasMatch(text);
  if (wantsPleatedFilter) {
    final match = findHvac(
      (name) =>
          name.contains('pleated air filter') &&
          (matrix == null || name.contains(matrix)),
    );
    if (match != null) return match;
  }

  final wantsAcDisconnect =
      RegExp(r'\b(ac|a/c)\b').hasMatch(text) &&
      RegExp(r'\b(disconnect|disc)\b').hasMatch(text);
  if (wantsAcDisconnect) {
    final amps = RegExp(r'\b(30|60)\s*(?:a|amp)\b').firstMatch(text)?.group(1);
    final match = findHvac(
      (name) =>
          name.contains('ac disconnect') &&
          (amps == null || name.contains('$amps amp')),
    );
    if (match != null) return match;
  }

  final wantsFilterRackOrGrille = RegExp(
    r'\b(filter\s*rack|return\s*(?:filter\s*)?grille)\b',
  ).hasMatch(text);
  if (wantsFilterRackOrGrille) {
    final match = findHvac(
      (name) =>
          name.contains('filter rack or return grille') &&
          (matrix == null || name.contains(matrix)),
    );
    if (match != null) return match;
  }

  final wantsFloatSwitch =
      RegExp(r'\bfloat\s*switch\b').hasMatch(text) ||
      RegExp(r'\bwet\s*switch\b').hasMatch(text);
  if (wantsFloatSwitch) {
    final wantsWetSwitch = RegExp(r'\bwet\s*switch\b').hasMatch(text);
    final wantsSecondaryPan = RegExp(r'\b(secondary|sec|pan)\b').hasMatch(text);
    final match = findHvac(
      (name) =>
          name.contains('float switch') &&
          (!wantsWetSwitch || name.contains('wet switch')) &&
          (!wantsSecondaryPan || name.contains('secondary pan')),
    );
    if (match != null) return match;
  }

  final wantsSecondaryDrainPan =
      RegExp(r'\b(secondary|sec)\b').hasMatch(text) &&
      RegExp(r'\bdrain\s*pan\b').hasMatch(text);
  if (wantsSecondaryDrainPan) {
    final match = findHvac(
      (name) =>
          name.contains('condensate service material') &&
          name.contains('secondary drain pan') &&
          (matrix == null || name.contains(matrix)),
    );
    if (match != null) return match;
  }

  final wantsLiquidLineDrier =
      RegExp(r'\bliquid\s*line\b').hasMatch(text) &&
      RegExp(r'\bfilter\s*dri(?:er|er)\b').hasMatch(text);
  if (wantsLiquidLineDrier) {
    final size = _nominalReceiptSize(text);
    final match = findHvac(
      (name) =>
          name.contains('liquid line filter drier') &&
          (size == null || name.contains('$size in')),
    );
    if (match != null) return match;
  }

  final wantsCondensateTablets =
      RegExp(r'\b(condensate|drain\s*pan|drain)\b').hasMatch(text) &&
      RegExp(r'\b(tablets?|tabs?)\b').hasMatch(text);
  if (wantsCondensateTablets) {
    final match = findHvac((name) => name.contains('condensate drain tablets'));
    if (match != null) return match;
  }

  return null;
}
