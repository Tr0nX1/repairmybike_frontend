pluginManagement {
    // Resolve plugins from local mirror first, then public portals
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == "org.gradle.kotlin.kotlin-dsl" && requested.version == "5.1.2") {
                useModule("org.gradle.kotlin:gradle-kotlin-dsl-plugins:5.1.2")
            }
        }
    }
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
        // Local offline mirror containing kotlin-dsl plugin
        maven { url = uri("gradle/local-maven") }
        // Public repositories (used when network is available)
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
