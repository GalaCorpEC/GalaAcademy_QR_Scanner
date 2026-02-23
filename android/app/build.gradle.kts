plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.h"
    // Use explicit SDK versions instead of relying on the Flutter
    // plugin's providers, which in some setups can be unavailable at
    // configuration time and trigger errors such as
    // "Cannot query the value of this provider because it has no value
    // available." These hardcoded values match the defaults produced by
    // recent Flutter templates. Bump compile/target SDK to 36 to satisfy
    // plugins like mobile_scanner.
    compileSdk = 36
    // ndkVersion was previously pulled from the Flutter plugin. In most
    // projects it's safe to omit this and let the Android Gradle plugin
    // use its default. Remove if you run into NDk-specific build issues.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.h"
        // Hardcode the minimum/target SDKs so that the Java compile task
        // can resolve its dependencies independent of any provider values.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
