plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.io.File
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
val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val releaseKeystorePresent = keystorePropertiesFile.exists()

if (releaseBuildRequested && !releaseKeystorePresent) {
    throw GradleException(
        "android/key.properties not found. " +
            "Run: powershell -ExecutionPolicy Bypass -File android/tool/generate_release_keystore.ps1"
    )
}

// Validate Android SDK setup
fun validateAndroidSdk() {
    val androidHome = System.getenv("ANDROID_HOME") ?: System.getProperty("android.home")
    if (androidHome == null || androidHome.isEmpty()) {
        throw GradleException(
            "❌ ANDROID_HOME is not set.\n" +
            "Set ANDROID_HOME to your Android SDK location (e.g., C:\\Users\\USERNAME\\AppData\\Local\\Android\\sdk)\n" +
            "For detailed setup instructions, see: android/SETUP.md"
        )
    }
    
    val cmdlineToolsPath = File(androidHome).resolve("cmdline-tools/latest/bin/sdkmanager.bat")
    if (!cmdlineToolsPath.exists()) {
        throw GradleException(
            "❌ Android SDK cmdline-tools not found at: $cmdlineToolsPath\n" +
            "Follow the setup instructions in android/SETUP.md to install cmdline-tools\n" +
            "Quick setup: powershell -ExecutionPolicy Bypass -File android/tool/quick_fix.ps1"
        )
    }
}

android {
    namespace = "com.lesgo.rider"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"
    
    // Validate Android SDK before building
    // validateAndroidSdk()  // Disabled for APK build

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
        if (releaseKeystorePresent) {
            create("release") {
                keyAlias = requireKeystoreProperty(keystoreProperties, "keyAlias")
                keyPassword = requireKeystoreProperty(keystoreProperties, "keyPassword")
                storePassword = requireKeystoreProperty(keystoreProperties, "storePassword")
                storeFile = rootProject.file(requireKeystoreProperty(keystoreProperties, "storeFile"))
                if (!storeFile!!.exists()) {
                    throw GradleException("Keystore not found at ${storeFile!!.absolutePath}")
                }
            }
        }
    }

    defaultConfig {
        applicationId = "com.lesgo.rider"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    buildTypes {
        release {
            if (releaseKeystorePresent) {
                signingConfig = signingConfigs.getByName("release")
            }
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
