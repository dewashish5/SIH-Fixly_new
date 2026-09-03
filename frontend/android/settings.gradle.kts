pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

val localProperties = java.util.Properties().apply {
    val file = file("local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

val mapboxDownloadsToken =
    localProperties.getProperty("SDK_REGISTRY_TOKEN")
        ?: System.getenv("SDK_REGISTRY_TOKEN")
        ?: ""

gradle.beforeProject {
    if (mapboxDownloadsToken.isNotEmpty()) {
        extensions.extraProperties.set("SDK_REGISTRY_TOKEN", mapboxDownloadsToken)
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
