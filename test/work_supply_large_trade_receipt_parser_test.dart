import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  group('large trade receipt parser coverage', () {
    test('plumbing receipt matrix covers high-volume pipe and fittings', () {
      _expectTradeMatch(
        'PVC SCH40 3/4 X 10FT PIPE',
        'Plumbing',
        containsName: ['PVC Schedule 40 Pipe'],
      );
      _expectTradeMatch(
        '3/4IN X 100FT PEX PIPE RED',
        'Plumbing',
        containsName: ['PEX Tubing'],
      );
      _expectTradeMatch(
        '4IN X 10FT PVC DWV PIPE',
        'Plumbing',
        containsName: ['PVC DWV Pipe'],
      );
      _expectTradeMatch(
        '1/2 CU CXC 90 ELL',
        'Plumbing',
        containsName: ['Copper 90 Elbow'],
      );
      _expectTradeMatch(
        'PVC S40 3/4 SXF ADAPT',
        'Plumbing',
        containsName: ['PVC Schedule 40 Female Adapter'],
      );
      _expectTradeMatch(
        '3 IN PVC DWV SAN TEE',
        'Plumbing',
        containsName: ['PVC DWV Sanitary Tee'],
      );
      _expectTradeMatch(
        '1/2 X 6 BI NIPPLE',
        'Plumbing',
        containsName: ['Black Iron Nipple'],
      );
      _expectTradeMatch(
        '3/8 BRS COMP UNION',
        'Plumbing',
        containsName: ['Brass Compression Union'],
      );
      _expectTradeMatch(
        '1/2 PUSH FIT SUPPLY STOP',
        'Plumbing',
        containsName: ['Push-Fit Supply Stop'],
      );
      _expectTradeMatch(
        '3/4 PVC BALL VALVE',
        'Plumbing',
        containsName: ['PVC Ball Valve'],
      );
      _expectTradeMatch(
        'TOILET WAX RING KIT',
        'Plumbing',
        containsName: ['Toilet Wax Ring'],
      );
      _expectTradeMatch(
        'TOILET FILL VALVE',
        'Plumbing',
        containsName: ['Toilet Fill Valve'],
      );
      _expectTradeMatch(
        'WATER HEATER T&P RELIEF VALVE',
        'Plumbing',
        containsName: ['T and P relief valve', 'Water Heater Repair Part'],
      );
      _expectTradeMatch(
        'CONDENSATE PUMP TUBING',
        'Plumbing',
        containsName: ['Condensate Pump Tubing'],
      );
    });

    test('electrical receipt matrix covers high-volume wire and devices', () {
      _expectTradeMatch(
        '12-2 WG ROMEX 250FT',
        'Electrical',
        exactName: '12/2 NM-B Cable',
      );
      _expectTradeMatch(
        '12 AWG RED THHN 500FT',
        'Electrical',
        containsName: ['12 AWG Red', '500 ft', 'Copper THHN THWN Wire'],
      );
      _expectTradeMatch(
        '20A 1P BRKR',
        'Electrical',
        exactName: '20 Amp Single-Pole Breaker',
      );
      _expectTradeMatch(
        '20A GFCI RECEPT WHITE 10PK',
        'Electrical',
        containsName: ['Wiring Device'],
      );
      _expectTradeMatch(
        '1/2 EMT SET SCREW CONN',
        'Electrical',
        exactName: '1/2 in EMT Connector',
      );
      _expectTradeMatch(
        '3/4 EMT CPLG SET SCREW',
        'Electrical',
        exactName: '3/4 in EMT Coupling',
      );
      _expectTradeMatch(
        'WINGED WIRE NUT 100PK',
        'Electrical',
        containsName: ['Winged', '100 Pack', 'Wire Connector'],
      );
      _expectTradeMatch(
        '2 IN WEATHERHEAD SERVICE HEAD',
        'Electrical',
        containsName: ['Service Entrance Accessory'],
      );
      _expectTradeMatch(
        'OLD WORK SINGLE GANG DEVICE BOX',
        'Electrical',
        containsName: ['Old Work', 'Electrical Box'],
      );
      _expectTradeMatch(
        '4IN SQUARE JUNCTION BOX',
        'Electrical',
        containsName: ['Junction Box'],
      );
      _expectTradeMatch(
        'SINGLE GANG BOX EXTENDER',
        'Electrical',
        containsName: ['Box Extender'],
      );
      _expectTradeMatch(
        '200A MAIN BREAKER PANEL',
        'Electrical',
        containsName: ['Main Breaker Panel'],
      );
      _expectTradeMatch(
        '4FT LED SHOP LIGHT',
        'Electrical',
        containsName: ['4 ft LED Shop Light'],
      );
      _expectTradeMatch(
        'HARDWIRED SMOKE ALARM BATTERY BACKUP',
        'Electrical',
        containsName: ['Smoke Alarm'],
      );
    });

    test('tile receipt matrix covers high-volume setting and shower stock', () {
      _expectTradeMatch(
        '12X24 MATTE PORCELAIN FLOOR TILE',
        'Tile',
        containsName: ['12 x 24 in', 'Matte Porcelain'],
      );
      _expectTradeMatch(
        '50LB GRAY LFT MORTAR',
        'Tile',
        containsName: ['50 lb Gray', 'LFT Mortar'],
      );
      _expectTradeMatch(
        '1QT CHARCOAL EPOXY GROUT',
        'Tile',
        containsName: ['1 qt Charcoal', 'Epoxy Grout'],
      );
      _expectTradeMatch(
        'WHITE CERAMIC QUARTER ROUND TRIM',
        'Tile',
        containsName: ['Quarter Round Trim'],
      );
      _expectTradeMatch(
        'FOAM BOARD WASHER 100PK',
        'Tile',
        containsName: ['Foam Board Washer'],
      );
      _expectTradeMatch(
        'KERDI FIX SEALANT TUBE',
        'Tile',
        containsName: ['Kerdi Fix Sealant'],
      );
      _expectTradeMatch(
        '60X60 SHOWER PAN EXTENSION',
        'Tile',
        containsName: ['Shower Pan Extension'],
      );
      _expectTradeMatch(
        '7IN PORCELAIN DIAMOND BLADE',
        'Tile',
        containsName: ['Porcelain Diamond Blade'],
      );
      _expectTradeMatch(
        '3FT X 33FT WATERPROOFING MEMBRANE',
        'Tile',
        containsName: ['3 ft x 33 ft', 'Waterproofing Membrane'],
      );
      _expectTradeMatch(
        'PIPE SEAL WATERPROOFING COLLAR',
        'Tile',
        containsName: ['Pipe Seal Waterproofing'],
      );
      _expectTradeMatch(
        '1GAL TILE MEMBRANE PRIMER',
        'Tile',
        containsName: ['Tile Membrane Primer'],
      );
      _expectTradeMatch(
        '25 SQ FT ELECTRIC FLOOR HEAT MAT',
        'Tile',
        containsName: ['Floor Heat Mat'],
      );
      _expectTradeMatch(
        '1/4 X 3/8 NOTCHED TROWEL',
        'Tile',
        containsName: ['1/4 x 3/8', 'Notched Trowel'],
      );
      _expectTradeMatch(
        'GROUT HAZE REMOVER QUART',
        'Tile',
        containsName: ['Grout Haze Remover'],
      );
      _expectTradeMatch(
        'GREEN GLASS PICKETT BACKSPLASH TILE',
        'Tile',
        containsName: ['Green', 'Glass', 'Pickett Backsplash Tile'],
      );
      _expectTradeMatch(
        'SLATE TEXTURED PORCELAIN 12X24 FLOOR TILE',
        'Tile',
        containsName: ['Slate', 'Textured', 'Porcelain', '12 x 24 in'],
      );
      _expectTradeMatch(
        'TUMBLED TRAVERTINE MOSAIC SHEET',
        'Tile',
        containsName: ['Tumbled Travertine', 'Mosaic Sheet'],
      );
      _expectTradeMatch(
        '8FT MATTE BLACK 3/8 JOLLY EDGE TRIM',
        'Tile',
        containsName: ['8 ft Matte Black', '3/8 in', 'Jolly Edge Trim'],
      );
      _expectTradeMatch(
        '4X48 CARRARA MARBLE THRESHOLD',
        'Tile',
        containsName: ['4 x 48 in Carrara Marble Threshold'],
      );
      _expectTradeMatch(
        '1/2 3X5 CEMENT BACKER BOARD',
        'Tile',
        containsName: ['1/2 in', '3 x 5 ft', 'Cement Backer Board'],
      );
      _expectTradeMatch(
        '50LB SELF LEVELING UNDERLAYMENT',
        'Tile',
        containsName: ['Self Leveling Underlayment', '50 lb'],
      );
      _expectTradeMatch(
        'ANTI FRACTURE MEMBRANE ROLL',
        'Tile',
        containsName: ['Anti Fracture Membrane Roll'],
      );
      _expectTradeMatch(
        '48X60 LEFT DRAIN FOAM SHOWER TRAY KIT',
        'Tile',
        containsName: ['48 x 60 in', 'Left Drain', 'Foam Shower Tray Kit'],
      );
      _expectTradeMatch(
        '42IN SATIN STAINLESS LINEAR DRAIN CHANNEL',
        'Tile',
        containsName: ['42 in', 'Satin Stainless', 'Linear Drain Channel'],
      );
      _expectTradeMatch(
        '16X28 TILE READY SHOWER NICHE',
        'Tile',
        containsName: ['16 x 28 in', 'Tile Ready Shower Niche'],
      );
      _expectTradeMatch(
        '72IN WATERPROOF SHOWER CURB',
        'Tile',
        containsName: ['72 in', 'Waterproof Shower Curb'],
      );
      _expectTradeMatch(
        '33FT WATERPROOFING SEAM TAPE ROLL',
        'Tile',
        containsName: ['33 ft', 'Waterproofing Seam Tape Roll'],
      );
      _expectTradeMatch(
        '40 SQ FT RADIANT FLOOR HEAT CABLE KIT',
        'Tile',
        containsName: ['40 sq ft', 'Radiant Floor Heat Cable Kit'],
      );
      _expectTradeMatch(
        '54 SQ FT HEAT CABLE UNCOUPLING MEMBRANE ROLL',
        'Tile',
        containsName: ['54 sq ft', 'Heat Cable Uncoupling Membrane Roll'],
      );
      _expectTradeMatch(
        '3/16 500PK TILE LEVELING WEDGE',
        'Tile',
        containsName: ['3/16 in', '500 Pack', 'Tile Leveling Wedge'],
      );
      _expectTradeMatch(
        '1-3/8 DIAMOND TILE HOLE SAW',
        'Tile',
        containsName: ['1-3/8 in', 'Diamond Tile Hole Saw'],
      );
      _expectTradeMatch(
        '3/4X9/16 STAINLESS NOTCHED TROWEL',
        'Tile',
        containsName: ['3/4 x 9/16 in', 'Stainless Notched Trowel'],
      );
      _expectTradeMatch(
        '5GAL NON POROUS SURFACE PRIMER',
        'Tile',
        containsName: ['5 gal', 'Non Porous Surface Primer'],
      );
      _expectTradeMatch(
        '1GAL NATURAL STONE SEALER',
        'Tile',
        containsName: ['1 gal', 'Natural Stone Sealer'],
      );
      _expectTradeMatch(
        '24X48 MATTE CARRARA RECTIFIED PORCELAIN TILE',
        'Tile',
        containsName: ['24 x 48 in', 'Carrara', 'Matte', 'Rectified Tile'],
      );
      _expectTradeMatch(
        'SAGE GLASS HEX MOSAIC SHEET',
        'Tile',
        containsName: ['Sage', 'Glass', 'Hex Mosaic Sheet'],
      );
      _expectTradeMatch(
        '6X6 RED QUARRY COVE BASE TILE',
        'Tile',
        containsName: ['6 x 6 in', 'Red', 'Quarry', 'Cove Base Tile'],
      );
    });
  });
}

void _expectTradeMatch(
  String receiptLine,
  String trade, {
  String? exactName,
  List<String> containsName = const [],
}) {
  final match = matchReceiptLineToCatalog(
    receiptLine,
    tradeScope: trade,
    maxCandidates: 120,
  );
  expect(match, isNotNull, reason: receiptLine);
  expect(match!.item.trade, trade, reason: receiptLine);
  if (exactName != null) {
    expect(match.item.name, exactName, reason: receiptLine);
  }
  for (final expected in containsName) {
    expect(match.item.name, contains(expected), reason: receiptLine);
  }
  expect(
    match.confidenceLevel,
    ReceiptConfidenceLevel.good,
    reason: receiptLine,
  );
}
