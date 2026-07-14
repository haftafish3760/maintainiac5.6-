part of 'expense_receipt_parser.dart';

String _normalizeFuelSignalText(String value) {
  return value
      .toLowerCase()
      .replaceAllMapped(RegExp(r'\b(\d{1,4}),(\d{2,4})\b'), (match) {
        return '${match.group(1)}.${match.group(2)}';
      })
      .replaceAll(RegExp(r'\bpr[1i!|]ce\b'), 'price')
      .replaceAll(RegExp(r'\bv[0o]l\b'), 'vol')
      .replaceAll(RegExp(r'\bqnty\b'), 'quantity')
      .replaceAll(RegExp(r'\bgal[oó]nes\b'), 'gallons')
      .replaceAll(RegExp(r'\bgal[0o]nes\b'), 'gallons')
      .replaceAll(RegExp(r'\bgal[oó]n\b'), 'gallon')
      .replaceAll(RegExp(r'\blitros\b'), 'liters')
      .replaceAll(RegExp(r'\blitro\b'), 'liter')
      .replaceAll(RegExp(r'\bgas\s*oil\b'), 'diesel')
      .replaceAll(RegExp(r'\bgas\s+natural\s+licuado\b'), 'lng')
      .replaceAll(RegExp(r'\bgas\s+natural\s+renovable\b'), 'rng')
      .replaceAll(RegExp(r'\bgas\s+natural\s+vehicular\b'), 'cng')
      .replaceAll(RegExp(r'\bgnv\b'), 'cng')
      .replaceAll(RegExp(r'\bglp\b'), 'lpg')
      .replaceAll(RegExp(r'\bgas\s+licuado(?:\s+de\s+petr[oó]leo)?\b'), 'lpg')
      .replaceAll(RegExp(r'\bhidr[oó]geno\b'), 'hydrogen')
      .replaceAll(RegExp(r'\bmagna\b'), 'gasoline')
      .replaceAll(RegExp(r'\bventa\s+(?:de\s+)?c[0o]mbustible\b'), 'fuel sale')
      .replaceAll(RegExp(r'\bc[0o]mbustible\s+de\s+carrera\b'), 'racing fuel')
      .replaceAll(RegExp(r'\bnitrometano\b'), 'nitromethane')
      .replaceAll(RegExp(r'\bturbosina\b'), 'jet fuel')
      .replaceAll(RegExp(r'\bgasolina\s+de\s+aviaci[oó]n\b'), 'avgas')
      .replaceAll(RegExp(r'\bcombustible\b'), 'fuel')
      .replaceAll(RegExp(r'\bc[0o]mbustible\b'), 'fuel')
      .replaceAll(RegExp(r'\bgasolina\b'), 'gasoline')
      .replaceAll(RegExp(r'\betanol\b'), 'ethanol')
      .replaceAll(RegExp(r'\bdi[eé]sel\b'), 'diesel')
      .replaceAll(RegExp(r'\bd[1i][eé]sel\b'), 'diesel')
      .replaceAll(RegExp(r'\bfluido\s+de\s+escape\s+diesel\b'), 'def')
      .replaceAll(RegExp(r'\bpr[e3]c1[o0]\b'), 'price')
      .replaceAll(RegExp(r'\b(?:precio|price)\s+efectivo\b'), 'cash price')
      .replaceAll(RegExp(r'\b(?:precio|price)\s+cr[eé]dito\b'), 'credit price')
      .replaceAll(RegExp(r'\bqueroseno\b'), 'kerosene')
      .replaceAll(RegExp(r'\bgas\s+natural\s+comprimido\b'), 'cng')
      .replaceAll(RegExp(r'\benerg[ií]a\b'), 'energy')
      .replaceAll(RegExp(r'\bcarga\s+parcial\b'), 'partial')
      .replaceAll(RegExp(r'\bcarga\s+el[eé]ctrica\b'), 'charging')
      .replaceAll(RegExp(r'\bcarga\b'), 'charging')
      .replaceAll(RegExp(r'\blleno\b'), 'full')
      .replaceAll(RegExp(r'\bparcial\b'), 'partial')
      .replaceAll(RegExp(r'\btanque\b'), 'tank')
      .replaceAll(RegExp(r'\bel[eé]ctrico\b'), 'electric')
      .replaceAll(RegExp(r'\bel[eé]ctrica\b'), 'electric')
      .replaceAll(
        RegExp(r'\bprecio\s*/?\s*(?:gal[oó]n|gallon|gal)\b'),
        'price/gal',
      )
      .replaceAll(
        RegExp(r'\bprecio\s+por\s+(?:gal[oó]n|gallon|gal)\b'),
        'price per gal',
      )
      .replaceAll(
        RegExp(r'\bprecio\s*/?\s*(?:litro|liter|litre|l)\b'),
        'price/liter',
      )
      .replaceAll(
        RegExp(r'\bprecio\s+por\s+(?:litro|liter|litre|l)\b'),
        'price per liter',
      )
      .replaceAll(
        RegExp(r'\b(?:precio|tarifa)\s*(?:/|por\s+)?kwh\b'),
        'price/kwh',
      )
      .replaceAll(RegExp(r'\btarifa\b'), 'rate')
      .replaceAll(RegExp(r'\bventa\s+(?:de\s+)?combustible\b'), 'fuel sale')
      .replaceAll(RegExp(r'\bod[oó]metro\b'), 'odometer')
      .replaceAll(RegExp(r'\bgall[0o]ns\b'), 'gallons')
      .replaceAll(RegExp(r'\bga[1il|!]\b'), 'gal')
      .replaceAll(RegExp(r'\bgalns\b'), 'gallons')
      .replaceAll(RegExp(r'\bpp[6g]\b'), 'ppg')
      .replaceAll(RegExp(r'\bd[1i!|]esel\b'), 'diesel')
      .replaceAll(RegExp(r'\bmethan[0o]l\b'), 'methanol')
      .replaceAll(RegExp(r'\bunl(?:eaded)?\b'), 'unleaded')
      .replaceAll(RegExp(r'\bfue[1i!|]\b'), 'fuel');
}
