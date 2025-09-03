plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

android {
    namespace = "com.rivorya.takaslyapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rivorya.takaslyapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        
        // Dinamik sürüm yönetimi - Flutter'dan bağımsız
        versionCode = 33  // Her build'de artırılacak
        versionName = "1.0.2"  // Semantic version
    }

    // Load keystore properties if present (android/key.properties)
    val keystorePropertiesFile = file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { stream ->
            keystoreProperties.load(stream)
        }
    }

    signingConfigs {
        if (keystoreProperties.isNotEmpty()) {
            create("release") {
                val storeFilePath = keystoreProperties.getProperty("storeFile")
                if (!storeFilePath.isNullOrBlank()) {
                    val candidates = listOf(
                        file(storeFilePath),
                        // resolve relative to android/ (parent of app)
                        file("../$storeFilePath"),
                        rootProject.file(storeFilePath),
                        rootProject.file("android/$storeFilePath"),
                        rootProject.file("android/app/$storeFilePath")
                    )
                    val resolved = candidates.firstOrNull { it.exists() }
                    if (resolved != null) {
                        storeFile = resolved
                    } else {
                        // Fallback to given path; Gradle will error if missing which is explicit
                        storeFile = file(storeFilePath)
                    }
                }
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
                enableV4Signing = true
            }
        }
    }

    buildTypes {
        release {
            // Release build için keystore zorunlu
            if (keystoreProperties.isEmpty()) {
                throw GradleException("Release build için keystore gerekli! android/key.properties dosyası bulunamadı veya boş.")
            }
            
            // Keystore yapılandırmasını kontrol et ve gerekirse oluştur
            val releaseSigningConfig = signingConfigs.maybeCreate("release")
            if (releaseSigningConfig.storeFile == null) {
                throw GradleException("Release signing config yapılandırılamadı! Keystore dosyası bulunamadı.")
            }
            
            signingConfig = releaseSigningConfig
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
