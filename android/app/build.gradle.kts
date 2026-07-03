import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

android {
    namespace = "tech.neokred.olympiadpro_teacher"
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
        applicationId = "tech.neokred.olympiadpro"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Vidyora"
    }

    // Three installable apps from one codebase — pair each with its Dart
    // entrypoint, e.g. `flutter build apk --flavor student -t lib/main_student.dart`.
    flavorDimensions += "app"
    productFlavors {
        create("student") {
            dimension = "app"
            applicationId = "tech.neokred.vidyora.student"
            manifestPlaceholders["appLabel"] = "Vidyora"
        }
        create("teacher") {
            dimension = "app"
            applicationId = "tech.neokred.vidyora.educator"
            manifestPlaceholders["appLabel"] = "Vidyora Educator"
        }
        create("admin") {
            dimension = "app"
            applicationId = "tech.neokred.vidyora.admin"
            manifestPlaceholders["appLabel"] = "Vidyora Admin"
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
