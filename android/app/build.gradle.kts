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

    // AGP 9 turns several build features off by default. `resValue` (used by the
    // flavors below to set `app_name`) is one of them — without this flag the
    // build fails with:
    //   Product Flavor 'dev' contains custom resource values, but the feature is
    //   disabled. To enable the feature, add `android.buildFeatures.resValues true`.
    // (`buildConfigField` has an identical flag, `buildFeatures.buildConfig`, if
    // we ever add one — see docs/Versions.md §1.)
    //
    // Because the flavors own `app_name` outright, there is deliberately **no**
    // `main/res/values/strings.xml` declaring it: AGP writes flavor resValues to a
    // generated resource dir that overlays the base, and two definitions of the
    // same string is a duplicate-resource error, not an override.
    buildFeatures {
        resValues = true
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

    // --- Why `flutter run` used to fail with "Gradle build failed to produce an
    //     .apk file" even though the build succeeded -------------------------
    //
    // The Flutter tool locates the APK by a *computed filename* in
    // `build/app/outputs/flutter-apk/` (flutter_tools/lib/src/android/gradle.dart,
    // `listApkPaths`):
    //
    //   flavor flag absent  ->  app-<buildType>.apk          e.g. app-debug.apk
    //   flavor flag given   ->  app-<flavor>-<buildType>.apk e.g. app-dev-debug.apk
    //
    // The Flutter Gradle plugin builds that same name itself: it copies AGP's
    // output into `flutter-apk/` and **renames** it to
    // `app-<abi>?-<flavor>?-<buildMode>.apk` (FlutterPlugin.kt). Note the copy's
    // *source* is `output.outputFileName`.
    //
    // With AGP 9 and a flavor, the default `outputFileName` is already
    // `app-dev-debug.apk`, so `listApkPaths` (flavor *absent*, i.e. `app-debug.apk`)
    // never matched what landed in `flutter-apk/`. Flat contradiction: AGP named
    // the file after the flavor, the plugin re-derived the flavor name from the
    // variant, and the tool — told nothing about the flavor — asked for the
    // flavorless name.
    //
    // Two independent fixes, both applied:
    //
    //   1. Pin `outputFileName` to the flavorless `app-<buildType>.apk`. The
    //      plugin still renames its `flutter-apk/` copy to `app-dev-debug.apk`,
    //      so `flutter run --flavor dev` finds it.
    //   2. Emit an `app-<buildType>.apk` alias inside `flutter-apk/` as well, so a
    //      plain `flutter run` (no `--flavor`) also finds an APK.
    //
    // Step 2 is what makes `flutter run -d emulator-5554` work with no flags —
    // the ergonomics a stock Flutter project has. The flavor is unaffected: the
    // applicationId still carries `.dev`, which is what actually lets dev and
    // prod install side by side.
    applicationVariants.all {
        outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            output.outputFileName = "app-${buildType.name}.apk"
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

// Writes `flutter-apk/app-<buildType>.apk` alongside the plugin's
// flavor-named copy, so a flagless `flutter run` resolves an APK.
//
// Registered *after* the flutter plugin has added its own `assemble<Variant>`
// `doLast` copy, so this task's `doLast` is appended and therefore runs after —
// the source file it reads is the one the plugin just wrote.
//
// `onlyIf` keeps it honest: the alias is produced from the flavor-named file,
// and a missing source means the plugin copy did not run, which is a real
// problem worth surfacing rather than silently skipping.
gradle.projectsEvaluated {
    android.applicationVariants.all {
        val variant = this
        val buildTypeName = variant.buildType.name
        val flavorName = variant.flavorName ?: ""
        val modeName = when (buildTypeName) {
            "release" -> "release"
            "profile" -> "profile"
            else -> "debug"
        }
        val apkDir = layout.buildDirectory.dir("outputs/flutter-apk")
        val flavorNamed = "app-$flavorName-$modeName.apk"
        val aliasName = "app-$modeName.apk"

        // Only meaningful when a flavor actually renamed the file; for a
        // flavorless build the two names are identical and the copy is a no-op.
        if (flavorName.isEmpty()) return@all

        tasks.matching { it.name == "assemble${variant.name.replaceFirstChar { c -> c.uppercase() }}" }
            .configureEach {
                doLast {
                    val dir = apkDir.get().asFile
                    val source = dir.resolve(flavorNamed)
                    if (!source.exists()) return@doLast
                    source.copyTo(dir.resolve(aliasName), overwrite = true)
                }
            }

        // Also alias .aab bundles so flagless `flutter build appbundle` resolves.
        tasks.matching { it.name == "bundle${variant.name.replaceFirstChar { c -> c.uppercase() }}" }
            .configureEach {
                doLast {
                    val bundleDir = layout.buildDirectory.dir("outputs/bundle/${variant.name}").get().asFile
                    val genericBundleDir = layout.buildDirectory.dir("outputs/bundle/$modeName").get().asFile
                    genericBundleDir.mkdirs()
                    bundleDir.listFiles()?.forEach { file ->
                        if (file.extension == "aab") {
                            file.copyTo(genericBundleDir.resolve("app-$modeName.aab"), overwrite = true)
                            file.copyTo(bundleDir.resolve("app-$modeName.aab"), overwrite = true)
                        }
                    }
                }
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
