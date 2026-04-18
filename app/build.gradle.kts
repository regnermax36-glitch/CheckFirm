import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
keystoreProperties.load(FileInputStream(keystorePropertiesFile))

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.androidx.room)
    alias(libs.plugins.google.gms)
    alias(libs.plugins.google.ksp)
    alias(libs.plugins.kotlin.parcelize)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "com.illusion.checkfirm"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.illusion.checkfirm"
        minSdk = 28
        targetSdk = 36
        versionCode = 58
        versionName = "11.2.1"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

    androidResources {
        generateLocaleConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    buildFeatures {
        viewBinding = true
        buildConfig = true
    }

    packaging {
        resources {
            pickFirsts += arrayOf(
                "META-INF/LICENSE.md",
                "META-INF/NOTICE.md"
            )
        }
    }
}

kotlin {
    jvmToolchain(jdkVersion = 21)
}

room {
    schemaDirectory("$projectDir/schemas")
}

dependencies {
    implementation(project(":oneui"))
    implementation(libs.appcompat)

    implementation(libs.recyclerview)
    implementation(libs.splashscreen)
    implementation(libs.ksoup)


    implementation(libs.bundles.angus)
    implementation(libs.bundles.bases)
    implementation(libs.bundles.coroutines)
    implementation(libs.bundles.datas)
    implementation(libs.bundles.designs)
    implementation(libs.bundles.firebases)
    implementation(libs.bundles.ktors)
    implementation(libs.bundles.lifecycles)

    ksp(libs.room.compiler)
}