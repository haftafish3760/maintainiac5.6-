part of 'maintenance_receipt_parser.dart';

final _maintenanceRetailMerchant = RegExp(
  r"\b(?:advance\s*auto\s*parts|advanceautoparts|auto\s*zone|o\s*[’'`]?\s*reilly\s*auto\s*parts|napa\s*auto\s*parts|carquest|pep\s*boys|wal\s*-?\s*mart|costco(?:\s*wholesale)?|sam[’'`]?\s*s\s*club|tractor\s*supply(?:\s*co)?|rural\s*king)\b",
);
final _purchaseSignal = RegExp(
  r'\b(?:amount paid|cashier|register|change due|retail sale|sku|part no|item price)\b',
);
final _serviceSignal = RegExp(
  r'\b(?:service performed|work completed|completed services?|repair order|work order|technician|labor|vehicle mileage|customer vehicle|installed|replaced|replacement|oil change|tire rotation|wheel alignment|front[- ]end alignment|wheel balancing|tire balancing|road force balanc(?:e|ing)|brake inspection|suspension inspection|front[- ]end inspection|flush service|registration renewed|renewal completed|inspection passed|inspection completed)\b',
);
final _strongServiceSignal = RegExp(
  r'\b(?:service performed|work completed|repair order|work order|technician|labor|vehicle mileage|customer vehicle|installed|replaced|registration renewed|renewal completed|inspection passed|inspection completed)\b',
);
final _performedOnLine = RegExp(
  r'\b(?:service|labor|installed|replaced|replacement|performed|change|rotation|flush|renewed|passed|completed)\b',
);
final _estimateOrQuoteSignal = RegExp(
  r'\b(?:estimate|quotation|quote|proposed work)\b',
);
final _explicitCompletionSignal = RegExp(
  r'\b(?:service performed|work completed|paid in full|installed|replaced|renewed|inspection passed)\b',
);
final _notCompletedLine = RegExp(
  r'\b(?:declined|deferred|recommended|recommendation|estimate|estimated|quote|quoted|proposed|not performed|not authorized|not approved|cancel(?:ed|led)|customer refused|future service)\b',
);
final _notCompletedSectionHeading = RegExp(
  r'^(?:(?:declined|deferred|recommended|recommendations|estimate|estimated|quoted|proposed)(?: services?| work| items?)?|requested services?|customer (?:request(?:s|ed)?(?: services?)?|concerns?|states?|declined|refused)|(?:authorized|approved)(?: services?| work| repairs?)|not (?:authorized|approved)|cancel(?:ed|led)(?: services?| work| repairs?)|no work performed|inspection (?:results?|findings?)|(?:pending|future)(?: services?| work| repairs?)|parts on order|awaiting parts|diagnos(?:is|tic (?:results?|findings?))|(?:technician|tech) (?:notes?|comments?)|observations?|advisories?|vehicle health (?:report|results?))\s*:?\s*$',
);
final _completedSectionHeading = RegExp(
  r'^(?:service performed|performed services?|work completed|completed services?)\s*:?\s*$',
);
final _returnOrExchangeLine = RegExp(
  r'\b(?:return(?:ed)?|refund(?:ed)?|exchange(?:d)?|voided item)\b',
);
final _coreAdjustmentLine = RegExp(
  r'\b(?:core\s+(?:charge|deposit|credit|refund|return|exchange)|(?:credit|refund|return)\s+core)\b',
);
final _transactionPolicyLine = RegExp(r'\b(?:return|refund|exchange) policy\b');
final _standaloneReturnHeading = RegExp(
  r'^(?:return|refund|exchange)\s*:?\s*$',
);
final _purchaseLineSignal = RegExp(r'\b(?:sku|part|qty|item)\b');
final _transactionCompletionSignal = RegExp(
  r'\b(?:amount paid|retail sale|paid|payment|tender|cash|credit|debit|total)\b',
);
final _pricedLine = RegExp(r'(?:^|\s)[-+]?\$?\d+[.,]\d{2}(?:\s|$)');
final _metadataLine = RegExp(
  r'\b(?:store|date|time|receipt|invoice|phone|address|subtotal|tax|total|amount paid)\b',
);
final _serviceOdometerOutPattern = RegExp(
  r'\b(?:odometer|odo|mileage)\s*out\s*[:#]?\s*(\d{3,8})\b',
);
final _serviceOdometerInPattern = RegExp(
  r'(?:\b(?:odometer|odo|mileage)\s*in|\bmiles in)\s*[:#]?\s*(\d{3,8})\b',
);
final _serviceOdometerPattern = RegExp(
  r'\b(?<!prior )(?<!previous )(?<!last )(?<!last recorded )(?:odometer|odo|vehicle mileage|mileage|current miles)\s*[:#]?\s*(\d{3,8})\b',
);
final _dueOdometerPattern = RegExp(
  r'\b(?:next service due|next service|next due|due at|service due at|next oil change)\D{0,24}(\d{4,8})\b',
);
final _intervalMilesPattern = RegExp(
  r'\b(?:due in|interval|every|next service in)\D{0,16}(\d{3,6})\s*(?:mi|mile|miles)\b',
);
final _serviceOdometerKilometersPattern = RegExp(
  r'\b(?:odometer|odo|mileage)(?:\s*(?:in|out))?\s*[:#]?\s*\d{3,8}\s*(?:kms?|kilomet(?:er|re)s?)\b',
);
final _dueOdometerKilometersPattern = RegExp(
  r'\b(?:next service due|next service|next due|due at|service due at|next oil change)\D{0,24}\d{4,8}\s*(?:kms?|kilomet(?:er|re)s?)\b',
);
final _intervalKilometersPattern = RegExp(
  r'\b(?:due in|interval|every|next service in)\D{0,16}\d{3,6}\s*(?:kms?|kilomet(?:er|re)s?)\b',
);
final _intervalMonthsPattern = RegExp(
  r'\b(?:due in|interval|every|next service in)\D{0,16}(\d{1,2})\s*(?:mo|month|months)\b',
);
