# ReflectionsOS Integration - Quick Start Guide

This guide provides a quick overview of how to integrate ReflectionsOS watch functionality with Superstar Avatar.

## Prerequisites

1. **Hardware**: ReflectionsOS watch with ESP32-S3
2. **Flutter Package**: Add `flutter_blue_plus` for BLE communication
3. **Firmware**: Custom ReflectionsOS firmware with BLE GATT server

## Quick Integration Steps

### 1. Add BLE Dependency

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_blue_plus: ^1.0.0  # For BLE connectivity
```

Run:
```bash
flutter pub get
```

### 2. Update ReflectionsService

The `ReflectionsService` class in `lib/services/reflections_service.dart` has placeholder TODOs that need to be implemented with actual BLE code. The structure is ready - you just need to:

1. Uncomment and implement the BLE scanning code
2. Implement device connection
3. Implement data transmission/reception
4. Test with your ReflectionsOS hardware

### 3. Integrate into Activity Flow

Example integration in activity completion:

```dart
import 'services/reflections_service.dart';

Future<void> completeActivityWithGesture(ActivityScript activity) async {
  final reflectionsService = ReflectionsService();
  
  // Connect to watch if not already connected
  if (!reflectionsService.isConnected) {
    // Scan and connect to watch
    await reflectionsService.scanForDevices().first.then((device) {
      return reflectionsService.connectToWatch(device['id']!);
    });
  }
  
  // Map activity to expected gesture
  final expectedGesture = mapActivityToGesture(activity);
  
  // Wait for gesture verification
  final verified = await reflectionsService.verifyActivityWithGesture(
    activity.id,
    expectedGesture,
  );
  
  if (verified) {
    // Complete activity on blockchain
    await blockchainService.completeActivity(
      activityId: activity.id,
      avatarId: avatar.id,
      proof: 'gesture_verified', // Include gesture signature
    );
    
    // Trigger haptic celebration
    await reflectionsService.triggerHaptic(
      ReflectionsService.HapticPattern.celebration,
    );
  }
}
```

### 4. Display Avatar Data on Watch

```dart
Future<void> syncAvatarToWatch(Avatar avatar) async {
  final reflectionsService = ReflectionsService();
  
  if (!reflectionsService.isConnected) {
    return; // Skip if not connected
  }
  
  // Convert avatar to JSON
  final avatarJson = avatar.toJson();
  
  // Sync to watch
  await reflectionsService.syncAvatarToWatch(avatarJson);
  
  // Update power levels display
  final powersJson = avatar.powers.map((p) => {
    'type': p.type.toString(),
    'level': p.level,
    'experience': p.experience,
    'maxExperience': p.maxExperience,
  }).toList();
  
  await reflectionsService.updatePowerDisplay(powersJson);
}
```

### 5. Gesture-to-Power Mapping

Create a helper function to map gestures to activities:

```dart
ReflectionsService.GestureType mapActivityToGesture(ActivityScript activity) {
  // Map based on primary power
  switch (activity.primaryPower) {
    case PowerType.Courage:
      return ReflectionsService.GestureType.highFive;
    case PowerType.Creativity:
      return ReflectionsService.GestureType.drawing;
    case PowerType.Connection:
      return ReflectionsService.GestureType.handshake;
    case PowerType.Insight:
      return ReflectionsService.GestureType.thinking;
    case PowerType.Kindness:
      return ReflectionsService.GestureType.wave;
    default:
      return ReflectionsService.GestureType.singleTap;
  }
}
```

## BLE Protocol Specification

### Service UUID
- **Service**: `0000fe40-cc7a-482a-984a-7f2ed5b3e58f`

### Characteristics

1. **Command Characteristic** (`0000fe41-cc7a-482a-984a-7f2ed5b3e58f`)
   - Write only
   - Send commands to watch (haptic, display updates, etc.)
   - Format: JSON strings

2. **Data Characteristic** (`0000fe42-cc7a-482a-984a-7f2ed5b3e58f`)
   - Write only
   - Send avatar data, power levels, etc.
   - Format: JSON strings (may need chunking for large payloads)

3. **Gesture Characteristic** (`0000fe43-cc7a-482a-984a-7f2ed5b3e58f`)
   - Notify/Read
   - Receive gesture events from watch
   - Format: JSON strings with gesture data

### Command Formats

#### Haptic Command
```json
{
  "type": "haptic",
  "pattern": "celebration"
}
```

#### Avatar Sync Command
```json
{
  "type": "avatar_sync",
  "data": {
    "id": "avatar123",
    "name": "My Avatar",
    "powers": [...],
    "totalExperience": 5000
  }
}
```

#### Power Update Command
```json
{
  "type": "power_update",
  "powers": [
    {
      "type": "Courage",
      "level": 5,
      "experience": 2500,
      "maxExperience": 3000
    }
  ]
}
```

### Gesture Event Format

```json
{
  "gesture": "highFive",
  "confidence": 0.95,
  "timestamp": 1640000000
}
```

## ReflectionsOS Firmware Requirements

The ESP32 firmware needs to implement:

1. **BLE GATT Server** with the service and characteristics above
2. **Gesture Recognition** - Process accelerometer/IMU data and detect gestures
3. **Display Manager** - Render avatar data on TFT display
4. **Haptic Controller** - Trigger vibration patterns
5. **GPS Data Transmission** (optional, for location features)

### Example Firmware Structure

```cpp
// BLE Service setup
BLEServer *pServer = BLEDevice::createServer();
BLEService *pService = pServer->createService(serviceUuid);

// Gesture characteristic
BLECharacteristic *pGestureChar = pService->createCharacteristic(
  gestureCharacteristicUuid,
  BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
);

// Command characteristic
BLECharacteristic *pCommandChar = pService->createCharacteristic(
  commandCharacteristicUuid,
  BLECharacteristic::PROPERTY_WRITE
);

pCommandChar->setCallbacks(new CommandCallbacks());

// Gesture detection loop
void loop() {
  GestureType gesture = detectGesture(); // Your gesture recognition logic
  
  if (gesture != NONE) {
    String gestureJson = "{\"gesture\":\"" + gestureToString(gesture) + "\"}";
    pGestureChar->setValue(gestureJson.c_str());
    pGestureChar->notify();
  }
  
  delay(100);
}
```

## Testing Checklist

- [ ] BLE device discovery works
- [ ] Connection to ReflectionsOS watch succeeds
- [ ] Gesture events are received from watch
- [ ] Avatar data syncs to watch display
- [ ] Haptic feedback triggers correctly
- [ ] Activity verification flow works end-to-end
- [ ] Power level updates display correctly
- [ ] Error handling works (disconnection, timeouts)

## Next Steps

1. **Hardware Setup**: Get ReflectionsOS watch hardware
2. **Firmware Development**: Implement BLE GATT server in ESP32 firmware
3. **Flutter Implementation**: Complete BLE code in `ReflectionsService`
4. **Integration Testing**: Test gesture recognition and activity verification
5. **UI Integration**: Add watch connection UI to settings screen
6. **Smart Contract Updates**: Add gesture proof fields to activity contracts

## Troubleshooting

### Device Not Found
- Ensure ReflectionsOS watch is powered on and in pairing mode
- Check BLE permissions are granted in app settings
- Verify service UUID matches in firmware

### Connection Fails
- Check device is within BLE range (typically ~10 meters)
- Verify no other device is connected to watch
- Check firmware is running latest version

### Gestures Not Detected
- Verify gesture recognition is enabled in firmware
- Check gesture characteristic notifications are enabled
- Ensure accelerometer/IMU sensors are calibrated

### Data Not Syncing
- Check JSON format matches expected protocol
- Verify data chunking for large payloads
- Check firmware buffer sizes are sufficient

## Resources

- **Full Integration Analysis**: See `REFLECTIONSOS_INTEGRATION_ANALYSIS.md`
- **Flutter Blue Plus Docs**: https://pub.dev/packages/flutter_blue_plus
- **ESP32 BLE Documentation**: https://docs.espressif.com/projects/esp-idf/en/latest/esp32s3/api-reference/bluetooth/bt_ble.html
- **ReflectionsOS Repository**: https://github.com/tjcrowley/ReflectionsOS

---

**Note**: This is a reference implementation. Actual implementation details may vary based on your specific ReflectionsOS firmware version and hardware configuration.

