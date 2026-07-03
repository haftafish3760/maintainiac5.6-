import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_delivery_policy.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserDeliveryPolicySuite extends QaSuite {
  const WorkSupplyParserDeliveryPolicySuite()
    : super('inventory.delivery_policy_contract');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final policy = workSupplyTradePackDeliveryPolicy;
    final map = policy.toMap();

    _require(
      failures,
      policy.localMode.trim().isNotEmpty,
      'missing_local_mode',
      'Local downloadable pack mode must be named.',
    );
    _require(
      failures,
      policy.cloudMode.trim().isNotEmpty,
      'missing_cloud_mode',
      'Cloud-assisted parser fallback mode must be named.',
    );
    _require(
      failures,
      policy.cloudRequiresSubscription,
      'cloud_subscription_not_required',
      'Cloud fallback should require subscription before release cost exposure.',
    );
    _require(
      failures,
      policy.cloudRequiresInternet,
      'cloud_internet_not_required',
      'Cloud fallback must disclose internet requirement.',
    );
    _require(
      failures,
      policy.cloudReadBudgetPerReceipt > 0 &&
          policy.cloudReadBudgetPerReceipt <= 100,
      'cloud_receipt_read_budget_out_of_range',
      'Cloud reads per receipt must stay within the 100-read budget.',
    );
    _require(
      failures,
      policy.cloudReadBudgetPerUserPerDay > 0 &&
          policy.cloudReadBudgetPerUserPerDay <= 100,
      'cloud_daily_read_budget_out_of_range',
      'Cloud reads per user per day must stay within the 100-read target.',
    );
    _require(
      failures,
      map.toString().contains('offlineCapable: true') ||
          map.toString().contains('offlineCapable'),
      'missing_offline_local_disclosure',
      'Local pack mode must disclose offline capability.',
    );
    _require(
      failures,
      map.toString().contains('usesCarrierOrWifiData'),
      'missing_data_usage_disclosure',
      'Cloud fallback must disclose carrier/Wi-Fi data usage.',
    );

    return timer.finish(
      suite: name,
      checked: 8,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'policy': map,
        'contract':
            'Users can choose local downloadable packs or subscription cloud fallback without hidden Firebase/cellular cost surprises.',
      },
    );
  }

  void _require(
    List<QaFailure> failures,
    bool condition,
    String id,
    String message,
  ) {
    if (condition) return;
    failures.add(
      QaFailure(
        suite: name,
        id: id,
        message: message,
        severity: QaSeverity.error,
        suggestedFix:
            'Keep pack delivery policy explicit before exposing local/cloud parser options.',
        metadata: const {'triageCategory': QaFailureTriage.economics},
      ),
    );
  }
}
