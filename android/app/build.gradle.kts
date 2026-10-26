plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader -> localProperties.load(reader) }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode') ?: '1'
def flutterVersionName = localProperties.getProperty('flutter.versionName') ?: '1.0.0'

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.zsheesh.cashflow"
    compileSdk 34

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = '17' }

    sourceSets { main.java.srcDirs += 'src/main/kotlin' }

    defaultConfig {
        applicationId "com.zsheesh.cashflow"
        minSdk 21
        targetSdk 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            release {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            // Fallback ke debug signing bila key.properties tidak ada (default CI)
            signingConfig keystorePropertiesFile.exists()
                ? signingConfigs.release
                : signingConfigs.debug
            minifyEnabled false
            shrinkResources false
        }
    }
}

flutter { source '../..' }