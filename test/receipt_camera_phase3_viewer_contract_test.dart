import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';
import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test('Android receipt camera keeps full-preview chrome contract', () async {
    final android = await readAndroidReceiptCameraBridgeSources();
    final cameraActivity = android.cameraActivity;
    final settingsIcon = await File(
      'android/app/src/main/res/drawable/ic_receipt_camera_settings.xml',
    ).readAsString();
    final backIcon = await File(
      'android/app/src/main/res/drawable/ic_receipt_camera_back.xml',
    ).readAsString();
    final flashIcon = await File(
      'android/app/src/main/res/drawable/ic_receipt_camera_flash.xml',
    ).readAsString();
    final shutterIcon = await File(
      'android/app/src/main/res/drawable/ic_receipt_camera_shutter.xml',
    ).readAsString();

    expect(
      cameraActivity,
      contains(
        'previewView = PreviewView(this).apply {\n'
        '        layoutParams = FrameLayout.LayoutParams(\n'
        '            ViewGroup.LayoutParams.MATCH_PARENT,\n'
        '            ViewGroup.LayoutParams.MATCH_PARENT,',
      ),
    );
    expect(
      cameraActivity,
      contains('scaleType = PreviewView.ScaleType.FILL_CENTER'),
    );
    expect(
      cameraActivity,
      contains(
        'cameraRootView.addView(previewView)\n'
        '    cameraRootView.addView(buildReceiptFrameGuide())',
      ),
    );
    expect(cameraActivity, contains('setBackgroundColor(Color.TRANSPARENT)'));
    expect(
      cameraActivity,
      contains(
        'shutterButton = ImageButton(this).apply {\n'
        '        contentDescription = receiptCameraText("Take receipt photo", "Tomar foto del recibo")',
      ),
    );
    expect(
      cameraActivity,
      contains('setImageResource(R.drawable.ic_receipt_camera_shutter)'),
    );
    expect(cameraActivity, isNot(contains('android.R.drawable.ic_menu_camera')));
    expect(
      cameraActivity,
      contains(
        'layoutParams = LinearLayout.LayoutParams(dp(70), dp(70)).apply {',
      ),
    );
    expect(cameraActivity, contains('shape = GradientDrawable.OVAL'));
    expect(
      cameraActivity,
      contains(
        'topBar.addView(iconButton(receiptCameraText("Back", "Atrás"), R.drawable.ic_receipt_camera_back) {',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'topBar.addView(iconButton(receiptCameraText("Receipt camera settings", "Configuración de la cámara de recibos"), R.drawable.ic_receipt_camera_settings) {',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'torchButton = iconButton(\n'
        '        receiptCameraText("Turn light on", "Encender luz"),\n'
        '        R.drawable.ic_receipt_camera_flash,',
      ),
    );
    expect(
      cameraActivity,
      contains('text = receiptCameraText("Done", "Listo")'),
    );
    expect(
      cameraActivity,
      contains('text = receiptCameraText("Add Photo", "Agregar foto")'),
    );
    expect(cameraActivity, contains('visibility = View.GONE'));
    expect(cameraActivity, contains('maxLines = 1'));
    expect(cameraActivity, contains('ellipsize = TextUtils.TruncateAt.END'));
    expect(cameraActivity, contains('bottomReviewButton = Button(this).apply {'));
    expect(cameraActivity, isNot(contains('topBar.addView(doneButton)')));
    expect(cameraActivity, isNot(contains('doneButton = Button(this).apply {')));
    expect(
      cameraActivity,
      contains('WindowInsetsCompat.Type.displayCutout()'),
    );

    expect(settingsIcon, contains('android:viewportWidth="24"'));
    expect(settingsIcon, contains('android:viewportHeight="24"'));
    expect(backIcon, contains('android:viewportWidth="24"'));
    expect(backIcon, contains('android:viewportHeight="24"'));
    expect(backIcon, contains('M14.7,5.3L8,12'));
    expect(settingsIcon, isNot(contains('wrench')));
    expect(flashIcon, contains('android:pathData="M7,2h10l-3,8h5L9,22'));
    expect(shutterIcon, contains('android:viewportWidth="24"'));
    expect(shutterIcon, contains('android:viewportHeight="24"'));
    expect(shutterIcon, contains('M6,3h12a1,1'));
  });

  test('iOS receipt camera keeps full-preview chrome contract', () async {
    final ios = await readIosReceiptCameraBridgeSources();
    final cameraController = ios.cameraController;

    expect(cameraController, contains('preview.videoGravity = .resizeAspectFill'));
    expect(cameraController, contains('previewLayer?.frame = view.bounds'));
    expect(
      cameraController,
      contains('let settingsButton = iconButton(title: receiptCameraText("Receipt camera settings", "Configuración de la cámara de recibos"), symbol: "gearshape.fill")'),
    );
    expect(
      cameraController,
      contains('torchButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)'),
    );
    expect(cameraController, contains('bottomBar.backgroundColor = .clear'));
    expect(cameraController, contains('guidanceLabel.numberOfLines = 1'));
    expect(cameraController, contains('guidanceLabel.lineBreakMode = .byTruncatingTail'));
    expect(cameraController, contains('guidanceLabel.adjustsFontSizeToFitWidth = true'));
    expect(cameraController, contains('guidanceLabel.minimumScaleFactor = 0.82'));
    expect(cameraController, contains('let viewerInfoStack = UIStackView()'));
    expect(cameraController, contains('viewerInfoStack.axis = .vertical'));
    expect(cameraController, contains('viewerInfoStack.addArrangedSubview(buildSettingsStatusStrip())'));
    expect(cameraController, contains('viewerInfoStack.addArrangedSubview(previousSectionGuide)'));
    expect(cameraController, contains('updateViewerInfoStackVisibility()'));
    expect(
      cameraController,
      contains(
        'viewerInfoStack.isHidden =\n'
        '      settingsStatusStrip.isHidden &&\n'
        '      previousSectionGuidePanel.isHidden',
      ),
    );
    expect(
      cameraController,
      contains('shutterButton.setImage(UIImage(systemName: "doc.text.viewfinder"), for: .normal)'),
    );
    expect(cameraController, contains('shutterButton.layer.cornerRadius = 36'));
    expect(cameraController, contains('shutterButton.widthAnchor.constraint(equalToConstant: 72)'));
    expect(cameraController, contains('shutterButton.heightAnchor.constraint(equalToConstant: 72)'));
    expect(cameraController, contains('addPhotoButton.isHidden = true'));
    expect(cameraController, contains('bottomReviewButton.isHidden = true'));
    expect(cameraController, isNot(contains('topBar.addArrangedSubview(doneButton)')));
    expect(
      cameraController,
      contains('topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6)'),
    );
    expect(
      cameraController,
      contains('viewerInfoStack.topAnchor.constraint(equalTo: guidanceLabel.bottomAnchor, constant: 8)'),
    );
    expect(
      cameraController,
      contains('bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4)'),
    );
  });
}
