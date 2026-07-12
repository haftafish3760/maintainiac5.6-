import 'package:flutter/widgets.dart';

class MaintaniacLocalizations {
  const MaintaniacLocalizations(this.locale);

  static const supportedLocales = [Locale('en', 'US'), Locale('es', 'US')];
  static const delegate = _MaintaniacLocalizationsDelegate();

  final Locale locale;

  static MaintaniacLocalizations of(BuildContext context) {
    return Localizations.of<MaintaniacLocalizations>(
          context,
          MaintaniacLocalizations,
        ) ??
        const MaintaniacLocalizations(Locale('en', 'US'));
  }

  bool get isSpanish => locale.languageCode == 'es';

  String get receiptCameraTitle =>
      isSpanish ? 'Cámara de recibos' : 'Receipt Camera';
  String get adjustBrightness =>
      isSpanish ? 'Ajustar brillo' : 'Adjust brightness';
  String get takeReceiptPhoto =>
      isSpanish ? 'Tomar foto del recibo' : 'Take receipt photo';
  String get turnLightOn => isSpanish ? 'Encender luz' : 'Turn light on';
  String get turnLightOff => isSpanish ? 'Apagar luz' : 'Turn light off';
  String get receiptCameraSettings => isSpanish
      ? 'Configuración de cámara de recibos'
      : 'Receipt Camera Settings';
  String get brightnessUnavailable => isSpanish
      ? 'El ajuste de brillo no está disponible en esta cámara.'
      : 'Brightness adjustment is not available on this camera.';
  String get brightnessNativeControl => isSpanish
      ? 'Ajusta el brillo. El teléfono sigue controlando el enfoque automático y el tiempo de exposición.'
      : 'Adjust Brightness. The phone still controls autofocus and exposure timing.';
  String get addAnotherReceiptPhoto =>
      isSpanish ? 'Agregar otra foto' : 'Add Another Photo';
  String get addBottomReceiptSection =>
      isSpanish ? 'Agregar sección inferior' : 'Add Bottom Section';
  String get retakeReceiptPhoto => isSpanish ? 'Repetir foto' : 'Retake';
  String get cropReceiptPhoto => isSpanish ? 'Recortar' : 'Crop';
  String get savedProof => isSpanish ? 'Comprobante' : 'Proof';
  String get matchReceiptPhotos =>
      isSpanish ? 'Unir fotos' : 'Match Photos';
  String get cropCurrentReceiptPhoto =>
      isSpanish ? 'Recortar actual' : 'Crop Current';
  String get receiptPhoto => isSpanish ? 'Foto del recibo' : 'Receipt Photo';
  String receiptSectionOf(int current, int total) => isSpanish
      ? 'Sección $current de $total'
      : 'Section $current of $total';
  String get useReceipt => isSpanish ? 'Usar recibo' : 'Use Receipt';
  String get useAnyway => isSpanish ? 'Usar de todos modos' : 'Use Anyway';
  String get openingReceiptReview => isSpanish ? 'Abriendo' : 'Opening';
  String get checkingReceiptPhotos => isSpanish ? 'Revisando' : 'Checking';
  String get retakeRecommended =>
      isSpanish ? 'Se recomienda repetir' : 'Retake Recommended';
  String get checkPhotoBeforeUse => isSpanish
      ? 'Revise la foto antes de usarla'
      : 'Check Photo Before Use';
}

class _MaintaniacLocalizationsDelegate
    extends LocalizationsDelegate<MaintaniacLocalizations> {
  const _MaintaniacLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return MaintaniacLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<MaintaniacLocalizations> load(Locale locale) {
    final resolved = locale.languageCode == 'es'
        ? const Locale('es', 'US')
        : const Locale('en', 'US');
    return Future.value(MaintaniacLocalizations(resolved));
  }

  @override
  bool shouldReload(_MaintaniacLocalizationsDelegate old) => false;
}
