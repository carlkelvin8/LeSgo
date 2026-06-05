plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.io.FileInputStream
import java.util.Properties

fun loadGoogleMapsApiKey(rootDir: java.io.File): String {
    val secretsFile = rootDir.resolve("secrets.json")
    if (secretsFile.exists()) {
        val match = Regex(""""GOOGLE_MAPS_API_KEY"\s*:\s*"([^"]*)"""")
            .find(secretsFile.readText())
        val key = match?.groupValues?.getOrNull(1)?.trim().orEmpty()
        if (key.isNotBlank()) return key
    }

    val legacyKeyFile = rootDir.resolve("google_maps_api_key.txt")
    if (legacyKeyFile.exists()) {
        return legacyKeyFile.readText().trim()
    }

    return (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)?.trim().orEmpty()
}

fun loadKeystoreProperties(): Properties {
    val props = Properties()
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        props.load(FileInputStream(file))
    }
    return props
}

fun requireKeystoreProperty(props: Properties, name: String): String {
    val value = props.getProperty(name)?.trim().orEmpty()
    if (value.isEmpty() || value.startsWith("your-")) {
        throw GradleException(
            "Missing or placeholder '$name' in android/key.properties. " +
                "Run: powershell -ExecutionPolicy Bypass -File android/tool/generate_release_keystore.ps1"
        )
    }
    return value
}

val googleMapsApiKey = loadGoogleMapsApiKey(rootProject.projectDir.parentFile)
val keystoreProperties = loadKeystoreProperties()
val keystorePropertiesFile = rootProject.file("key.properties")

android {
    namespace = "com.lesgo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    signingConfigs {
        create("release") {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "android/key.properties not found. " +
                        "Run: powershell -ExecutionPolicy Bypass -File android/tool/generate_release_keystore.ps1"
                )
            }
            keyAlias = requireKeystoreProperty(keystoreProperties, "keyAlias")
            keyPassword = requireKeystoreProperty(keystoreProperties, "keyPassword")
            storePassword = requireKeystoreProperty(keystoreProperties, "storePassword")
            storeFile = rootProject.file(requireKeystoreProperty(keystoreProperties, "storeFile"))
            if (!storeFile!!.exists()) {
                throw GradleException("Keystore not found at ${storeFile!!.absolutePath}")
            }
        }
    }

    defaultConfig {
        applicationId = "com.lesgo.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
