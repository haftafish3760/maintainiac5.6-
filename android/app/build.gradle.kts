plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.maintainiac"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.maintainiac"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            pickFirsts += "**/libc++_shared.so"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    val cameraXVersion = "1.5.0"
    implementation("androidx.camera:camera-core:$cameraXVersion")
    implementation("androidx.camera:camera-camera2:$cameraXVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraXVersion")
    implementation("androidx.camera:camera-view:$cameraXVersion")
    implementation("androidx.core:core-performance:1.0.0")
    implementation("androidx.core:core-performance-play-services:1.0.0")
    implementation("androidx.exifinterface:exifinterface:1.4.2")
    implementation("com.google.guava:guava:33.4.8-android")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("org.opencv:opencv:4.14.0")
}

tasks.matching { it.name.startsWith("copyFlutterAssets") }.configureEach {
    doFirst {
        val variantName = name.removePrefix("copyFlutterAssets")
        if (variantName.isNotEmpty()) {
            val variantDir = variantName.replaceFirstChar { it.lowercase() }
            delete(
                layout.buildDirectory.dir(
                    "intermediates/assets/$variantDir/merge${variantName}Assets/flutter_assets",
                ),
            )
        }
    }
}
