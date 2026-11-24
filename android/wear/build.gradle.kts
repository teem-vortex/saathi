plugins {
    id("com.android.application")
}

android {
    namespace = "com.example.saathi.wear"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.saathi"
        minSdk = 33
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-wearable:20.0.1")
}
