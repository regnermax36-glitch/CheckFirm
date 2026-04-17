import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.library)
}

android {
    namespace = "com.bluesion.oneui"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
    }

    sourceSets {
        getByName("main") {
            java.srcDirs(
                "src/divider/kotlin",
                "src/edittext/kotlin",
                "src/spinner/kotlin",
                "src/switch/kotlin",
                "src/tab/kotlin"
            )
            res.srcDirs(
                "src/main/res",
                "src/checkbox/res",
                "src/divider/res",
                "src/edittext/res",
                "src/fab/res",
                "src/progress/res",
                "src/radiobutton/res",
                "src/spinner/res",
                "src/switch/res",
                "src/tab/res"
            )
        }
    }

    buildTypes {
        debug { isMinifyEnabled = false }
        release { isMinifyEnabled = false }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    buildFeatures {
        viewBinding = true
        dataBinding = true
    }
}

dependencies {
    implementation(libs.appcompat)
    implementation(libs.material)
}
