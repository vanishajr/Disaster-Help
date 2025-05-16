plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Add task to fix namespace issues for all Flutter plugins
tasks.register("fixPluginNamespaces") {
    doLast {
        val pubCacheDir = file("${System.getProperty("user.home")}/AppData/Local/Pub/Cache/hosted/pub.dev")
        if (pubCacheDir.exists()) {
            pubCacheDir.listFiles()?.forEach { pluginDir ->
                val buildGradle = file("${pluginDir.absolutePath}/android/build.gradle")
                if (buildGradle.exists()) {
                    var content = buildGradle.readText()
                    if (!content.contains("namespace")) {
                        // Extract group name from the build.gradle file
                        val groupMatch = Regex("group\\s+['\"]([^'\"]+)['\"]").find(content)
                        if (groupMatch != null) {
                            val group = groupMatch.groupValues[1]
                            content = content.replace(
                                "group '$group'",
                                "group '$group'\nnamespace '$group'"
                            )
                            buildGradle.writeText(content)
                            println("Added namespace to ${pluginDir.name}")
                        }
                    }
                }
            }
        }
    }
}

// Make the namespace fix task run before build
tasks.named("preBuild") {
    dependsOn("fixPluginNamespaces")
}

android {
    namespace = "com.example.disaster_help_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.disaster_help_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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
