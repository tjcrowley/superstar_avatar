#!/bin/bash
# Script to debug Android crashes

echo "=== Android Debug Helper ==="
echo ""

# Find adb command
ADB_CMD=""
if command -v adb &> /dev/null; then
    ADB_CMD="adb"
elif [ -n "$ANDROID_HOME" ]; then
    ADB_CMD="$ANDROID_HOME/platform-tools/adb"
elif [ -n "$ANDROID_SDK_ROOT" ]; then
    ADB_CMD="$ANDROID_SDK_ROOT/platform-tools/adb"
else
    # Try common locations
    if [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
        ADB_CMD="$HOME/Library/Android/sdk/platform-tools/adb"
    elif [ -f "$HOME/Android/Sdk/platform-tools/adb" ]; then
        ADB_CMD="$HOME/Android/Sdk/platform-tools/adb"
    fi
fi

if [ -z "$ADB_CMD" ] || [ ! -f "$ADB_CMD" ]; then
    echo "⚠️  ADB not found!"
    echo ""
    echo "To fix this, add Android SDK platform-tools to your PATH:"
    echo "  export PATH=\$PATH:\$HOME/Library/Android/sdk/platform-tools"
    echo ""
    echo "Or set ANDROID_HOME:"
    echo "  export ANDROID_HOME=\$HOME/Library/Android/sdk"
    echo ""
    echo "Then add to your ~/.zshrc or ~/.bash_profile"
    echo ""
    echo "For now, using Flutter's built-in log viewer..."
    echo ""
    flutter logs
    exit 0
fi

echo "✓ Found ADB at: $ADB_CMD"
echo ""

echo "1. Checking connected devices..."
flutter devices

echo ""
echo "2. Viewing Android logs (press Ctrl+C to stop)..."
echo "   Look for 'FATAL EXCEPTION' or 'AndroidRuntime' errors"
echo ""

# Use adb logcat to view logs
echo "Clearing old logs..."
"$ADB_CMD" logcat -c  # Clear old logs

echo ""
echo "Filtering for Flutter and app-specific logs..."
echo "Press Ctrl+C to stop"
echo ""

# Filter for Flutter, app package, and critical errors
"$ADB_CMD" logcat | grep -E "(flutter|superstar_avatar|AndroidRuntime|FATAL EXCEPTION|Exception|Error|E/|E flutter|E AndroidRuntime)" | grep -v -E "(NullBinder|GLSUser|TapAndPay|BugleRcsEngine|gwwo|ApkAssets)"

