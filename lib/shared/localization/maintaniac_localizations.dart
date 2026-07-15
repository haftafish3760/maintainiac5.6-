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
  String get deviceStorage => _text(
    'Device Storage',
    'Almacenamiento del dispositivo',
    'Stockage de l’appareil',
  );
  String get refreshStorage => _text(
    'Refresh storage',
    'Actualizar almacenamiento',
    'Actualiser le stockage',
  );
  String get storageUnavailable => _text(
    'Available storage could not be verified right now.',
    'No se pudo verificar el almacenamiento disponible en este momento.',
    'Le stockage disponible ne peut pas être vérifié pour le moment.',
  );
  String storageAvailable(String size) =>
      _text('$size available', '$size disponibles', '$size disponibles');
  String get storageHealthyForReceipts => _text(
    'Storage is healthy for receipt capture and local proof saving.',
    'El almacenamiento es suficiente para capturar recibos y guardar comprobantes locales.',
    'Le stockage est suffisant pour capturer des reçus et enregistrer des preuves locales.',
  );
  String get storageLowForReceipts => _text(
    'Storage is getting low. Consider freeing space before importing more receipts.',
    'El almacenamiento se está agotando. Libere espacio antes de importar más recibos.',
    'Le stockage commence à manquer. Libérez de l’espace avant d’importer d’autres reçus.',
  );
  String get storageCriticalForReceipts => _text(
    'Storage is critically low. Free space before capturing or importing another receipt.',
    'El almacenamiento está críticamente bajo. Libere espacio antes de capturar o importar otro recibo.',
    'Le stockage est extrêmement faible. Libérez de l’espace avant de capturer ou d’importer un autre reçu.',
  );
  String get storageCheckBeforeImport => _text(
    'Refresh to try again before importing a large receipt or PDF.',
    'Actualice e inténtelo de nuevo antes de importar un recibo o PDF grande.',
    'Actualisez avant d’importer un grand reçu ou PDF.',
  );
  String get receiptStorageSafetyNote => _text(
    'Receipt processing needs temporary device space. Maintainiac saves your records locally first and never deletes your photos or files to make room.',
    'El procesamiento de recibos necesita espacio temporal. Maintainiac guarda sus registros primero en el dispositivo y nunca elimina sus fotos o archivos para liberar espacio.',
    'Le traitement des reçus nécessite de l’espace temporaire. Maintainiac enregistre d’abord vos données sur l’appareil et ne supprime jamais vos photos ou fichiers pour faire de la place.',
  );
  String get scheduledBackup => _text(
    'Scheduled Backup',
    'Copia de seguridad programada',
    'Sauvegarde planifiée',
  );
  String get scheduledBackupIntro => _text(
    'Choose the times and connection type. Nothing transfers until you turn scheduled backup on.',
    'Elija las horas y el tipo de conexión. No se transfiere nada hasta que active la copia programada.',
    'Choisissez les heures et le type de connexion. Aucun transfert ne commence avant d’activer la sauvegarde planifiée.',
  );
  String get backUpOnMySchedule => _text(
    'Back up on my schedule',
    'Respaldar según mi horario',
    'Sauvegarder selon mon horaire',
  );
  String scheduledBackupRunsAt(String times) => _text(
    'Runs at $times.',
    'Se ejecuta a las $times.',
    'S’exécute à $times.',
  );
  String get scheduledBackupNeedsTime => _text(
    'Add at least one time before a backup can run.',
    'Agregue al menos una hora antes de que pueda ejecutarse una copia.',
    'Ajoutez au moins une heure avant qu’une sauvegarde puisse s’exécuter.',
  );
  String get addBackupTime =>
      _text('Add time', 'Agregar hora', 'Ajouter une heure');
  String get scheduledBackupConnection => _text(
    'Connection for scheduled backup',
    'Conexión para copia programada',
    'Connexion pour la sauvegarde planifiée',
  );
  String get wifiOnly => _text('Wi-Fi only', 'Solo Wi-Fi', 'Wi-Fi seulement');
  String get wifiOrMobileData => _text(
    'Wi-Fi or mobile data',
    'Wi-Fi o datos móviles',
    'Wi-Fi ou données mobiles',
  );
  String get scheduledBackupDeviceConsent => _text(
    'Scheduled backup is enabled only on this device. A restored device always asks again.',
    'La copia programada se habilita solo en este dispositivo. Un dispositivo restaurado siempre vuelve a preguntar.',
    'La sauvegarde planifiée est activée seulement sur cet appareil. Un appareil restauré demande toujours de nouveau.',
  );
  String get odometerPromptsByCategory => _text(
    'Odometer Prompts By Category',
    'Avisos de odómetro por categoría',
    'Demandes d’odomètre par catégorie',
  );
  String get odometerPromptExplanation => _text(
    'An odometer reading is always optional. Choose which expense categories should ask before you record the expense.',
    'La lectura del odómetro siempre es opcional. Elija qué categorías deben preguntar antes de registrar el gasto.',
    'La lecture de l’odomètre est toujours facultative. Choisissez les catégories qui doivent demander une lecture avant d’enregistrer la dépense.',
  );
  String get askForOdometerReading => _text(
    'Ask for an odometer reading',
    'Preguntar por una lectura de odómetro',
    'Demander une lecture d’odomètre',
  );
  String get odometerStillManual => _text(
    'You can still enter a reading manually.',
    'Aún puede ingresar una lectura manualmente.',
    'Vous pouvez toujours entrer une lecture manuellement.',
  );
  String get askForTheseCategories => _text(
    'Ask for these categories',
    'Preguntar para estas categorías',
    'Demander pour ces catégories',
  );
  String get recapTiles =>
      _text('Recap Tiles', 'Tarjetas de resumen', 'Tuiles de récapitulatif');
  String get showEverything =>
      _text('Show Everything', 'Mostrar todo', 'Tout afficher');
  String get recapTilesExplanation => _text(
    'Choose which tiles appear on the Expense Recap screen.',
    'Elija qué tarjetas aparecen en la pantalla de resumen de gastos.',
    'Choisissez les tuiles à afficher dans l’écran de récapitulatif des dépenses.',
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
