#!/bin/bash
# View only Flutter app logs (cleaner output)

# Find adb command
ADB_CMD=""
if command -v adb &> /dev/null; then
    ADB_CMD="adb"
elif [ -n "$ANDROID_HOME" ]; then
    ADB_CMD="$ANDROID_HOME/platform-tools/adb"
elif [ -n "$ANDROID_SDK_ROOT" ]; then
    ADB_CMD="$ANDROID_SDK_ROOT/platform-tools/adb"
else
    if [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
        ADB_CMD="$HOME/Library/Android/sdk/platform-tools/adb"
    elif [ -f "$HOME/Android/Sdk/platform-tools/adb" ]; then
        ADB_CMD="$HOME/Android/Sdk/platform-tools/adb"
    fi
fi

if [ -z "$ADB_CMD" ] || [ ! -f "$ADB_CMD" ]; then
    echo "ADB not found. Using flutter logs instead..."
    flutter logs
    exit 0
fi

echo "=== Flutter App Logs ==="
echo "Clearing old logs..."
"$ADB_CMD" logcat -c

echo ""
echo "Watching for Flutter app logs..."
echo "Press Ctrl+C to stop"
echo ""

# Filter for Flutter-specific logs only
"$ADB_CMD" logcat -s flutter:V "*:E" | grep -E "(flutter|superstar_avatar|Exception|Error|FATAL)"

