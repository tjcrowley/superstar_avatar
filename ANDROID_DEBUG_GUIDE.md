# Android Debugging Guide

## Viewing Crash Logs

### Method 1: Using ADB Logcat

1. Connect your Android device via USB
2. Enable USB debugging on your device
3. Run the debug script:
   ```bash
   ./debug_android.sh
   ```

Or manually:
```bash
# Clear old logs
adb logcat -c

# View logs in real-time
adb logcat | grep -E "(flutter|AndroidRuntime|FATAL|ERROR|superstar_avatar)"

# Save logs to file
adb logcat > crash_logs.txt
```

### Method 2: Using Flutter Run with Verbose

```bash
flutter run --verbose
```

This will show detailed output including any errors.

### Method 3: Check Flutter Logs

```bash
flutter logs
```

## Common Crash Causes

### 1. Missing Permissions
- Check `AndroidManifest.xml` has required permissions
- Camera permission for QR scanning
- Internet permission for blockchain calls

### 2. Initialization Errors
- Check if services initialize properly
- Look for errors in `main.dart` initialization
- Check contract addresses are valid

### 3. Null Pointer Exceptions
- Check if providers return null values
- Verify wallet is connected before blockchain calls
- Check avatar exists before accessing properties

### 4. Network Errors
- Check internet connection
- Verify RPC URL is accessible
- Check if contracts are deployed

## Debugging Steps

1. **Check Logs First**
   ```bash
   adb logcat | grep -i "error\|fatal\|exception"
   ```

2. **Run in Debug Mode**
   ```bash
   flutter run --debug
   ```

3. **Check Initialization**
   - Look for initialization messages in logs
   - Check if all services start successfully
   - Verify no exceptions during startup

4. **Test Individual Features**
   - Try wallet creation/import
   - Test avatar creation
   - Check blockchain interactions

## Error Screen

The app now includes an error screen that will show:
- The error message
- Option to restart the app
- In debug mode: option to copy error details

## Getting Help

When reporting crashes, include:
1. Full logcat output (from `adb logcat`)
2. Flutter verbose output (`flutter run --verbose`)
3. Steps to reproduce
4. Device information (`flutter doctor -v`)

