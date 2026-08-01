import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/localization/maintaniac_localizations.dart';

void main() {
  test('supports the United States and Canadian release locales', () {
    expect(MaintaniacLocalizations.supportedLocales, const [
      Locale('en', 'US'),
      Locale('es', 'US'),
      Locale('en', 'CA'),
      Locale('fr', 'CA'),
    ]);
  });

  test('resolves Spanish and Canadian French operational copy', () async {
    final spanish = await MaintaniacLocalizations.delegate.load(
      const Locale('es', 'US'),
    );
    final french = await MaintaniacLocalizations.delegate.load(
      const Locale('fr', 'CA'),
    );

    expect(spanish.takeReceiptPhoto, 'Tomar foto del recibo');
    expect(french.takeReceiptPhoto, 'Prendre une photo du reçu');
    expect(french.savedProofBlackAndWhite, 'noir et blanc');
    expect(spanish.deviceStorage, 'Almacenamiento del dispositivo');
    expect(french.storageAvailable('1 GB'), '1 GB disponibles');
    expect(spanish.milesUnit, 'Millas');
    expect(spanish.tripDistance, 'Distancia del viaje');
    expect(spanish.reviewDetectedItems, 'Revisar elementos detectados');
    expect(french.kilometersUnit, 'Kilomètres');
    expect(french.needsReview, 'À vérifier');
  });

  test(
    'uses the approved regional fallback for available language packs',
    () async {
      final mexicanSpanish = await MaintaniacLocalizations.delegate.load(
        const Locale('es', 'MX'),
      );
      final french = await MaintaniacLocalizations.delegate.load(
        const Locale('fr', 'FR'),
      );
      final canadianEnglish = await MaintaniacLocalizations.delegate.load(
        const Locale('en', 'CA'),
      );

      expect(mexicanSpanish.locale, const Locale('es', 'US'));
      expect(french.locale, const Locale('fr', 'CA'));
      expect(canadianEnglish.locale, const Locale('en', 'CA'));
    },
  );
}
