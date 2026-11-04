plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val keystorePath: String? = System.getenv("PC5_KEYSTORE")

android {
    namespace = "com.pc5.android"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.pc5.android"
        minSdk = 24
        targetSdk = 35
        versionCode = (System.getenv("PC5_VERSION_CODE") ?: "2").toInt()
        versionName = System.getenv("PC5_VERSION_NAME") ?: "2.0.0"
        resConfigs("en")
        ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64") }
    }

    signingConfigs {
        if (keystorePath != null) {
            create("release") {
                storeFile = File(keystorePath)
                storePassword = System.getenv("PC5_STORE_PASSWORD")
                keyAlias = System.getenv("PC5_KEY_ALIAS")
                keyPassword = System.getenv("PC5_KEY_PASSWORD")
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.findByName("release")
        }
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions { jvmTarget = "17" }

    packaging {
        jniLibs.useLegacyPackaging = false
        resources.excludes += setOf("META-INF/*.kotlin_module", "META-INF/DEPENDENCIES")
    }

    lint {
        abortOnError = false
    }
}

dependencies {
    implementation(files("libs/pc5core.aar"))
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.webkit:webkit:1.11.0")
    implementation("com.google.android.material:material:1.12.0")
}
