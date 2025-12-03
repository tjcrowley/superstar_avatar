# Android Troubleshooting Guide

## "Error waiting for a debug connection" Fix

This error usually means the app is crashing immediately on startup. Here's how to fix it:

### Step 1: Clean and Rebuild

```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

### Step 2: Check Logs Using Flutter

If `adb` is not available, use Flutter's built-in log viewer:

```bash
# In one terminal, run the app
flutter run

# In another terminal, view logs
flutter logs
```

### Step 3: Set Up ADB (Optional but Recommended)

Find your Android SDK location:
```bash
# On macOS, usually:
ls ~/Library/Android/sdk/platform-tools/adb

# Or check Flutter's Android SDK:
flutter doctor -v | grep "Android SDK"
```

Add to your `~/.zshrc` (or `~/.bash_profile`):
```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
```

Then reload:
```bash
source ~/.zshrc
```

### Step 4: View Logs with ADB

Once ADB is set up:
```bash
./debug_android.sh
```

Or manually:
```bash
adb logcat -c  # Clear logs
adb logcat | grep -E "(flutter|AndroidRuntime|FATAL|ERROR)"
```

### Step 5: Common Issues

#### Issue: App crashes immediately
**Solution**: Check initialization errors in logs. Look for:
- ✗ Failed to initialize...
- Exception in main()
- Null pointer exceptions

#### Issue: Build fails
**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

#### Issue: Emulator issues
**Solution**: 
- Restart the emulator
- Try a different emulator
- Use a physical device instead

### Step 6: Run in Release Mode (to bypass debug issues)

```bash
flutter run --release
```

This won't have debug features but can help identify if it's a debug-specific issue.

### Step 7: Check for Specific Errors

Look for these in the logs:
- `FATAL EXCEPTION` - App crash
- `AndroidRuntime` - Runtime errors
- `Exception` - Dart exceptions
- `Error` - General errors

## Quick Debug Commands

```bash
# View all Flutter logs
flutter logs

# View Android logs (if adb is available)
adb logcat | grep flutter

# Check connected devices
flutter devices

# Run with verbose output
flutter run --verbose

# Build APK to test
flutter build apk --debug
```

