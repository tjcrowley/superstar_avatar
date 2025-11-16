# Android Build Guide for Superstar Avatar

This guide walks you through compiling the Superstar Avatar Flutter app for Android.

## Prerequisites

### 1. Required Software

- **Flutter SDK** (3.6.2 or higher)
  ```bash
  flutter --version
  ```

- **Android Studio** (latest version recommended)
  - Download from: https://developer.android.com/studio

- **Java Development Kit (JDK)** 8 or higher
  ```bash
  java -version
  ```

- **Android SDK** (via Android Studio)
  - Android SDK Platform 34
  - Android SDK Build-Tools
  - Android SDK Command-line Tools

### 2. Environment Setup

1. **Install Flutter** (if not already installed):
   ```bash
   # Download Flutter SDK
   git clone https://github.com/flutter/flutter.git -b stable
   
   # Add to PATH
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **Install Android Studio**:
   - Download and install Android Studio
   - Open Android Studio and install Android SDK
   - Install Android SDK Platform 34
   - Install Android SDK Build-Tools

3. **Configure Flutter**:
   ```bash
   flutter doctor
   ```
   
   Fix any issues reported:
   ```bash
   flutter doctor --android-licenses
   ```

4. **Set Android Environment Variables** (optional but recommended):
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
   # OR
   export ANDROID_HOME=$HOME/Android/Sdk  # Linux
   
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/tools/bin
   ```

## Step-by-Step Build Process

### Step 1: Verify Flutter Setup

```bash
cd /path/to/superstar_avatar
flutter doctor
```

Ensure all checks pass, especially:
- ✅ Flutter (Channel stable)
- ✅ Android toolchain
- ✅ Android Studio
- ✅ Connected device (or emulator)

### Step 2: Get Dependencies

```bash
flutter pub get
```

This installs all packages listed in `pubspec.yaml`.

### Step 3: Check Android Configuration

Verify the following files are properly configured:

1. **`android/app/build.gradle`**:
   - `minSdk = 21` (required for mobile_scanner)
   - `targetSdk = 34`
   - `multiDexEnabled = true`

2. **`android/app/src/main/AndroidManifest.xml`**:
   - Camera permission
   - Internet permission
   - Application name and icon

### Step 4: Connect Android Device or Start Emulator

**Option A: Physical Device**
1. Enable Developer Options on your Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Settings → Developer Options → USB Debugging
3. Connect device via USB
4. Verify connection:
   ```bash
   flutter devices
   ```

**Option B: Android Emulator**
1. Open Android Studio
2. Tools → Device Manager
3. Create Virtual Device (if needed)
4. Start emulator
5. Verify connection:
   ```bash
   flutter devices
   ```

### Step 5: Build and Run (Debug)

```bash
# Run on connected device/emulator
flutter run

# Or build APK
flutter build apk --debug
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

### Step 6: Build Release APK

For testing release builds:

```bash
flutter build apk --release
```

The release APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Step 7: Build App Bundle (for Play Store)

For Google Play Store submission:

```bash
flutter build appbundle --release
```

The AAB file will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Configuration Details

### AndroidManifest.xml

The manifest includes:
- **Internet Permission**: Required for blockchain and API calls
- **Camera Permission**: Required for QR code scanning
- **Camera Features**: Optional camera features

### build.gradle

Key configurations:
- **minSdk**: 21 (Android 5.0) - Required for modern dependencies
- **targetSdk**: 34 (Android 14) - Latest Android version
- **multiDexEnabled**: true - Required for large dependency sets

### ProGuard Rules (for Release Builds)

Create `android/app/proguard-rules.pro`:

```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Web3
-keep class org.web3j.** { *; }
-dontwarn org.web3j.**

# Crypto
-keep class javax.crypto.** { *; }
-dontwarn javax.crypto.**
```

Then update `android/app/build.gradle`:

```gradle
buildTypes {
    release {
        signingConfig = signingConfigs.release
        minifyEnabled = true
        shrinkResources = true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

## Signing the App (for Release)

### Step 1: Generate Keystore

```bash
keytool -genkey -v -keystore ~/superstar-avatar-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias superstar-avatar
```

### Step 2: Create key.properties

Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=superstar-avatar
storeFile=/path/to/superstar-avatar-key.jks
```

**⚠️ Important**: Add `android/key.properties` to `.gitignore`!

### Step 3: Update build.gradle

Update `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing code ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.release
        }
    }
}
```

## Troubleshooting

### Common Issues

#### 1. "Gradle build failed"

**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

#### 2. "SDK location not found"

**Solution**:
Create `android/local.properties`:
```properties
sdk.dir=/path/to/Android/sdk
```

#### 3. "Camera permission denied"

**Solution**:
- Verify `AndroidManifest.xml` has camera permission
- Check runtime permissions in code (if targeting Android 6.0+)
- Test on physical device (emulators may have camera issues)

#### 4. "MultiDex error"

**Solution**:
- Ensure `multiDexEnabled = true` in `build.gradle`
- Add MultiDex dependency if needed:
  ```gradle
  dependencies {
      implementation 'androidx.multidex:multidex:2.0.1'
  }
  ```

#### 5. "Out of memory" during build

**Solution**:
Update `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m
```

#### 6. "Package name conflict"

**Solution**:
Update `applicationId` in `android/app/build.gradle`:
```gradle
applicationId = "com.yourcompany.superstaravatar"
```

#### 7. "Flutter dependencies not found"

**Solution**:
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build apk
```

### Build Performance

To speed up builds:

1. **Enable Gradle Daemon** (already enabled by default)
2. **Use Build Cache**:
   ```gradle
   // android/gradle.properties
   org.gradle.caching=true
   ```
3. **Parallel Builds**:
   ```gradle
   // android/gradle.properties
   org.gradle.parallel=true
   ```

## Testing the Build

### Install APK on Device

```bash
# Debug APK
adb install build/app/outputs/flutter-apk/app-debug.apk

# Release APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Test Features

1. **Wallet Creation**: Test wallet generation
2. **QR Code Scanning**: Test camera and QR scanning
3. **Blockchain Connection**: Test Polygon network connection
4. **Event Check-In**: Test check-in functionality
5. **Stripe Integration**: Test payment flows (use test mode)

## Pre-Launch Checklist

Before submitting to Play Store:

- [ ] App name and icon configured
- [ ] Version code and version name set
- [ ] App signed with release keystore
- [ ] ProGuard rules configured (if using)
- [ ] Permissions properly declared
- [ ] Privacy policy URL (if required)
- [ ] App tested on multiple devices
- [ ] All features tested
- [ ] No debug code left in release build
- [ ] App bundle built successfully
- [ ] Screenshots prepared
- [ ] Store listing prepared

## Next Steps

1. **Test on Multiple Devices**: Test on various Android versions and screen sizes
2. **Performance Testing**: Check app performance and memory usage
3. **Security Review**: Ensure no sensitive data in logs or code
4. **Play Store Setup**: Create Google Play Console account
5. **Prepare Store Assets**: Screenshots, descriptions, etc.

## Additional Resources

- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console](https://play.google.com/console)
- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)

## Quick Reference Commands

```bash
# Clean build
flutter clean && flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build app bundle
flutter build appbundle --release

# Install on connected device
flutter install

# Run on device
flutter run --release

# Check for issues
flutter doctor -v

# Analyze code
flutter analyze
```

---

**Need Help?** Check the troubleshooting section or review Flutter documentation for Android-specific issues.

