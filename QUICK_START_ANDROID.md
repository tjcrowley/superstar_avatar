# Quick Start: Build Android APK

## Fastest Path to Build

### 1. Verify Setup (30 seconds)
```bash
flutter doctor
```

### 2. Get Dependencies (1 minute)
```bash
flutter pub get
```

### 3. Connect Device or Emulator
- **Physical Device**: Enable USB debugging and connect
- **Emulator**: Start from Android Studio

### 4. Build and Install (2-5 minutes)
```bash
# Debug build (for testing)
flutter build apk --debug

# OR Release build (for distribution)
flutter build apk --release
```

### 5. Install on Device
```bash
# If device is connected
flutter install

# OR manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

## That's It! 🎉

Your APK is ready at:
- **Debug**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Release**: `build/app/outputs/flutter-apk/app-release.apk`

## Common First-Time Issues

### "Flutter not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### "Android SDK not found"
1. Open Android Studio
2. Tools → SDK Manager
3. Install Android SDK Platform 34
4. Set ANDROID_HOME:
   ```bash
   export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
   ```

### "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

## For Play Store Submission

Build App Bundle instead:
```bash
flutter build appbundle --release
```

File location: `build/app/outputs/bundle/release/app-release.aab`

---

**Full Guide**: See `ANDROID_BUILD_GUIDE.md` for detailed instructions.

