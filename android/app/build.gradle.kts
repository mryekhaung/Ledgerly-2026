plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yk.ledgerly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Placeholder bundle id (docs/Roadmap.md Phase 0). Namespace stays
        // flavor-independent; the applicationId carries the flavor suffix.
        applicationId = "com.yk.ledgerly"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Flavors (docs/Conventions.md §7): different bundle ids, different remote
    // adapters. `dev` is suffixed so both can be installed side by side.
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Ledgerly Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Ledgerly")
        }
    }

    buildTypes {
        release {
            // TODO(signing): configure a real release keystore before shipping.
            // Debug keys are used so `flutter run --release` works during Phase 0.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
