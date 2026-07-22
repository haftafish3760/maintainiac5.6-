# Consolidation report: Comand 1

- Applied: `True`
- Source remained unchanged: `true`

## Counts

- add: 7
- manual_merge: 34
- manual_review: 8
- skip_duplicate: 424
- skip_generated: 730

## Protected-feature signals

- expenses_payments: 9
- firebase_storage: 17
- jobs_maintenance_calendar: 9
- mapbox_dashboard_profiles: 10
- pdf_invoices_estimates: 11
- receipt_ocr_camera: 14
- trip_tracking: 5
- work_supplies_materials: 21

## Manual review

- `.gitignore` — same target path has different content
- `README.md` — same target path has different content
- `pubspec.lock` — same target path has different content
- `pubspec.yaml` — same target path has different content
- `android/build.gradle.kts` — same target path has different content
- `android/gradle.properties` — same target path has different content
- `android/settings.gradle.kts` — same target path has different content
- `android/app/build.gradle.kts` — same target path has different content
- `android/app/src/main/AndroidManifest.xml` — same target path has different content
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/commandone/MainActivity.kt` — unique content requires ownership or overlap review
- `ios/Flutter/Debug.xcconfig` — same target path has different content
- `ios/Flutter/Generated.xcconfig` — same target path has different content
- `ios/Flutter/Release.xcconfig` — same target path has different content
- `ios/Flutter/flutter_export_environment.sh` — same target path has different content
- `ios/Runner/AppDelegate.swift` — same target path has different content
- `ios/Runner/GeneratedPluginRegistrant.m` — same target path has different content
- `ios/Runner/Info.plist` — same target path has different content
- `ios/Runner.xcodeproj/project.pbxproj` — same target path has different content
- `ios/Runner.xcworkspace/contents.xcworkspacedata` — same target path has different content
- `ios/RunnerTests/RunnerTests.swift` — same target path has different content
- `lib/main.dart` — same target path has different content
- `lib/core/command_one_app.dart` — unique content requires ownership or overlap review
- `lib/features/admin_screens/admin_detail_screen.dart` — unique content requires ownership or overlap review
- `lib/features/admin_shell/admin_command_shell.dart` — unique content requires ownership or overlap review
- `lib/features/dashboard/command_dashboard_screen.dart` — unique content requires ownership or overlap review
- `lib/features/expense_health/expense_health_models.dart` — unique content requires ownership or overlap review
- `lib/features/expense_health/expense_health_panel.dart` — unique content requires ownership or overlap review
- `macos/Flutter/Flutter-Debug.xcconfig` — same target path has different content
- `macos/Flutter/Flutter-Release.xcconfig` — same target path has different content
- `macos/Flutter/GeneratedPluginRegistrant.swift` — same target path has different content
- `macos/Runner/Configs/AppInfo.xcconfig` — same target path has different content
- `macos/Runner.xcodeproj/project.pbxproj` — same target path has different content
- `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` — same target path has different content
- `macos/Runner.xcworkspace/contents.xcworkspacedata` — same target path has different content
- `test/expense_health_panel_test.dart` — unique content requires ownership or overlap review
- `test/widget_test.dart` — same target path has different content
- `windows/CMakeLists.txt` — same target path has different content
- `windows/flutter/generated_plugin_registrant.cc` — same target path has different content
- `windows/flutter/generated_plugins.cmake` — same target path has different content
- `windows/runner/Runner.rc` — same target path has different content
- `windows/runner/main.cpp` — same target path has different content

## Product-boundary result

- Content inspection identifies this as the separate `command_one` private admin/operations application with its own GitHub repository, not another Maintainiac customer-app checkout.
- The seven target-absent candidates were Command 1 admin code and Command 1 specifications, so they were excluded from 5.7 to preserve the product boundary and avoid unrelated duplicate app infrastructure.
- Maintainiac-related terms in the admin app explain the feature-signal matches; they are not evidence that its implementation belongs in the customer application.
- The source remained unchanged and its clean Git history is preserved in `haftafish3760/comand1`.
