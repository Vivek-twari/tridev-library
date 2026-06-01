pluginManagement {

    val flutterSdkPath =
        run {

            val properties =
                java.util.Properties()

            file("local.properties")
                .inputStream()
                .use {
                    properties.load(it)
                }

            val flutterSdkPath =
                properties.getProperty(
                    "flutter.sdk"
                )

            require(
                flutterSdkPath != null
            )

            flutterSdkPath
        }

    includeBuild(
        "$flutterSdkPath/packages/flutter_tools/gradle"
    )

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Retain 1.0.0; this version is fixed for Flutter configuration compatibility
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Upgrade to the latest stable release
    id("com.android.application") version "8.9.1" apply false

    // Upgrade to match the latest Kotlin ecosystem requirements
    id("org.jetbrains.kotlin.android") version "2.2.0" apply false

    // Upgrade to ensure compatibility with modern Firebase BOM features
    id("com.google.gms.google-services") version "4.4.2" apply false
}


include(":app")