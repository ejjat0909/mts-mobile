plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pos.mts"
    compileSdk = 35
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
        applicationId = "com.pos.mts"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
        // Enables code shrinking, obfuscation, and optimization for release builds
        isMinifyEnabled = false
        // Removes unused resources in the release build
        isShrinkResources = false
        // TODO: Add your own signing config for the release build.
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("com.google.code.gson:gson:2.8.9")
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    
    // AppCompat dependency for splash screen themes
    implementation("androidx.appcompat:appcompat:1.4.0")
    
    // Added printer dependencies
    implementation(files("libs/iminPrinterSDK-15_V1.3.2_2411051634.jar"))
    implementation(files("libs/IminLibs1.0.15.jar"))
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.0.0")
    implementation("io.reactivex.rxjava2:rxandroid:2.0.1")
    implementation(files("libs/IminStraElectronicSDK_V1.2.jar"))
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.github.iminsoftware:IminPrinterLibrary:V1.0.0.15")
    implementation("com.github.bumptech.glide:glide:4.16.0")
    annotationProcessor("com.github.bumptech.glide:compiler:4.16.0")
}

flutter {
    source = "../.."
}
