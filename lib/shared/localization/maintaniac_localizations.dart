import 'package:flutter/widgets.dart';

class MaintaniacLocalizations {
  const MaintaniacLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'US'),
    Locale('en', 'CA'),
    Locale('fr', 'CA'),
  ];
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
  bool get isFrenchCanadian =>
      locale.languageCode == 'fr' && locale.countryCode == 'CA';

  String _text(String english, String spanish, String frenchCanadian) {
    if (isFrenchCanadian) return frenchCanadian;
    return isSpanish ? spanish : english;
  }

  String get receiptCameraTitle =>
      _text('Receipt Camera', 'Cámara de recibos', 'Appareil photo des reçus');
  String get adjustBrightness =>
      _text('Adjust brightness', 'Ajustar brillo', 'Régler la luminosité');
  String get takeReceiptPhoto => _text(
    'Take receipt photo',
    'Tomar foto del recibo',
    'Prendre une photo du reçu',
  );
  String get turnLightOn =>
      _text('Turn light on', 'Encender luz', 'Allumer la lumière');
  String get turnLightOff =>
      _text('Turn light off', 'Apagar luz', 'Éteindre la lumière');
  String get receiptCameraSettings => _text(
    'Receipt Camera Settings',
    'Configuración de cámara de recibos',
    'Paramètres de l’appareil photo des reçus',
  );
  String get brightnessUnavailable => _text(
    'Brightness adjustment is not available on this camera.',
    'El ajuste de brillo no está disponible en esta cámara.',
    'Le réglage de la luminosité n’est pas disponible sur cet appareil photo.',
  );
  String get brightnessNativeControl => _text(
    'Adjust Brightness. The phone still controls autofocus and exposure timing.',
    'Ajusta el brillo. El teléfono sigue controlando el enfoque automático y el tiempo de exposición.',
    'Réglez la luminosité. Le téléphone contrôle toujours la mise au point automatique et le temps d’exposition.',
  );
  String get addAnotherReceiptPhoto => _text(
    'Add Another Photo',
    'Agregar otra foto',
    'Ajouter une autre photo',
  );
  String get addBottomReceiptSection => _text(
    'Add Bottom Section',
    'Agregar sección inferior',
    'Ajouter la section inférieure',
  );
  String get retakeReceiptPhoto => _text('Retake', 'Repetir foto', 'Reprendre');
  String get cropReceiptPhoto => _text('Crop', 'Recortar', 'Recadrer');
  String get savedProof => _text('Proof', 'Comprobante', 'Preuve');
  String get matchReceiptPhotos =>
      _text('Match Photos', 'Unir fotos', 'Associer les photos');
  String get cropCurrentReceiptPhoto =>
      _text('Crop Current', 'Recortar actual', 'Recadrer la photo actuelle');
  String get receiptPhoto =>
      _text('Receipt Photo', 'Foto del recibo', 'Photo du reçu');
  String receiptSectionOf(int current, int total) => _text(
    'Section $current of $total',
    'Sección $current de $total',
    'Section $current sur $total',
  );
  String get useReceipt => _text(
    'Save & Continue',
    'Guardar y continuar',
    'Enregistrer et continuer',
  );
  String get useAnyway =>
      _text('Use Anyway', 'Usar de todos modos', 'Utiliser quand même');
  String get openingReceiptReview => _text('Opening', 'Abriendo', 'Ouverture');
  String get checkingReceiptPhotos =>
      _text('Checking', 'Revisando', 'Vérification');
  String get retakeRecommended => _text(
    'Retake Recommended',
    'Se recomienda repetir',
    'Nouvelle prise recommandée',
  );
  String get checkPhotoBeforeUse => _text(
    'Check Photo Before Use',
    'Revise la foto antes de usarla',
    'Vérifiez la photo avant de l’utiliser',
  );
  String get preparingSavedProofPreview => _text(
    'Preparing saved proof preview',
    'Preparando vista previa del comprobante guardado',
    'Préparation de l’aperçu de la preuve enregistrée',
  );
  String get buildingSavedProofPreview => _text(
    'Building the smaller receipt image kept after reading.',
    'Creando la imagen más pequeña del recibo que se guarda después de leerlo.',
    'Création de la plus petite image du reçu conservée après sa lecture.',
  );
  String get savedProofBlackAndWhite =>
      _text('black and white', 'blanco y negro', 'noir et blanc');
  String get savedProofColor => _text('color', 'color', 'couleur');
  String savedProofDetail(String estimated, String saved, String mode) => _text(
    '$estimated saved proof image, $saved saved, $mode.',
    '$estimated de comprobante guardado, $saved ahorrados, $mode.',
    '$estimated de preuve enregistrée, $saved économisés, $mode.',
  );
  String savedProofNeedsReview(String estimated, String mode) => _text(
    '$estimated saved proof image, $mode. Check that the text is readable before using it.',
    '$estimated de comprobante guardado, $mode. Revise que el texto sea legible antes de usarlo.',
    '$estimated de preuve enregistrée, $mode. Vérifiez que le texte est lisible avant de l’utiliser.',
  );
  String savedProofOcrSourceFirst(String original) => _text(
    'The image behind this panel is the saved proof preview. Receipt assistance uses the clear OCR source first. Capture source $original.',
    'La imagen detrás de este panel es la vista previa del comprobante guardado. La asistencia de recibos usa primero la fuente OCR clara. Fuente capturada $original.',
    'L’image derrière ce panneau est l’aperçu de la preuve enregistrée. L’assistance des reçus utilise d’abord la source OCR claire. Source capturée : $original.',
  );
  String get savedProofSettingOnly => _text(
    'Receipt assistance uses the clear OCR source first. This setting only controls the smaller saved proof.',
    'La asistencia de recibos usa primero la fuente OCR clara. Este ajuste solo controla el comprobante guardado más pequeño.',
    'L’assistance des reçus utilise d’abord la source OCR claire. Ce réglage ne contrôle que la plus petite preuve enregistrée.',
  );
}

class _MaintaniacLocalizationsDelegate
    extends LocalizationsDelegate<MaintaniacLocalizations> {
  const _MaintaniacLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return switch (locale.languageCode.toLowerCase()) {
      'en' || 'es' || 'fr' => true,
      _ => false,
    };
  }

  @override
  Future<MaintaniacLocalizations> load(Locale locale) {
    final resolved = _resolveSupportedLocale(locale);
    return Future.value(MaintaniacLocalizations(resolved));
  }

  @override
  bool shouldReload(_MaintaniacLocalizationsDelegate old) => false;
}

Locale _resolveSupportedLocale(Locale locale) {
  final language = locale.languageCode.toLowerCase();
  final country = locale.countryCode?.toUpperCase();
  if (language == 'fr') return const Locale('fr', 'CA');
  if (language == 'es') return const Locale('es', 'US');
  if (language == 'en' && country == 'CA') return const Locale('en', 'CA');
  return const Locale('en', 'US');
}
