pluginManagement {
    // Resolve plugins from public portals in CI
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == "org.gradle.kotlin.kotlin-dsl" && requested.version == "5.1.2") {
                useModule("org.gradle.kotlin:gradle-kotlin-dsl-plugins:5.1.2")
            }
        }
    }
    val flutterSdkPath: String =
        run {
            // Prefer environment provided by CI action
            val fromEnv = System.getenv("FLUTTER_HOME") ?: System.getenv("FLUTTER_ROOT")
            if (fromEnv != null && fromEnv.isNotBlank()) {
                fromEnv
            } else {
                // Fallback to local.properties if present
                val propFile = file("local.properties")
                if (propFile.exists()) {
                    val properties = java.util.Properties()
                    propFile.inputStream().use { properties.load(it) }
                    properties.getProperty("flutter.sdk")
                        ?: throw GradleException("flutter.sdk not set in local.properties")
                } else {
                    throw GradleException("Flutter SDK path not found. Set FLUTTER_HOME/FLUTTER_ROOT or provide local.properties")
                }
            }
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
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
