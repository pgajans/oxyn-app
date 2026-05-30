import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.oxynapp.oxyn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.oxynapp.oxyn"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Some transitive Android dependencies recently started shipping alpha versions
// that require Android Gradle Plugin 9.1.0+ (newer than our AGP 8.11.1). Our
// previously shipped, working build used stable versions, so we pin/exclude
// these to keep building on the current AGP toolchain:
//   - androidx.compose.remote: pulled in by the AdMob adapter (via applovin_max);
//     the app does not use this Compose-based remote rendering path -> exclude.
//   - androidx.glance: pulled in by home_widget; pin to the latest stable (1.1.1)
//     instead of the 1.3.0-alpha that demands AGP 9.1.0+.
configurations.all {
    exclude(group = "androidx.compose.remote")
    resolutionStrategy.eachDependency {
        if (requested.group == "androidx.glance") {
            useVersion("1.1.1")
        }
    }
}

flutter {
    source = "../.."
}
