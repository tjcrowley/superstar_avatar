# How to Upgrade Gradle

## Current Gradle Version

Your project is currently using **Gradle 8.3**.

## Quick Upgrade Steps

### Method 1: Update gradle-wrapper.properties (Recommended)

1. **Edit the wrapper properties file**:
   ```bash
   # Navigate to project root
   cd /Users/darren/IdeaProjects/superstar_avatar
   
   # Edit the Gradle wrapper properties
   nano android/gradle/wrapper/gradle-wrapper.properties
   # OR use your preferred editor
   ```

2. **Update the distribution URL** to the latest version:
   ```properties
   distributionBase=GRADLE_USER_HOME
   distributionPath=wrapper/dists
   zipStoreBase=GRADLE_USER_HOME
   zipStorePath=wrapper/dists
   distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-all.zip
   ```

   **Latest stable versions** (as of 2024):
   - Gradle 8.5 (recommended for Flutter projects)
   - Gradle 8.6 (if available)
   - Gradle 8.7 (if available)

3. **Clean and rebuild**:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

### Method 2: Use Gradle Wrapper Command

```bash
cd android
./gradlew wrapper --gradle-version 8.5
cd ..
```

### Method 3: Update via Android Studio

1. Open Android Studio
2. File → Project Structure → Project
3. Change "Gradle Version" to latest
4. Click "Apply"

## Recommended Gradle Version for Flutter

For Flutter projects, **Gradle 8.3 to 8.5** is recommended:
- ✅ Stable and well-tested
- ✅ Compatible with Android Gradle Plugin 8.x
- ✅ Good performance

## Check Current Version

```bash
cd android
./gradlew --version
```

## Verify Upgrade

After upgrading, verify it worked:

```bash
cd android
./gradlew --version
```

You should see the new Gradle version.

## Troubleshooting

### "Gradle version too new" error

If you get compatibility errors, you may need to update the Android Gradle Plugin version in `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'  // Update this
    }
}
```

### "Unsupported class file major version" error

This means your Java version is incompatible. Check Java version:

```bash
java -version
```

Gradle 8.x requires **Java 17 or higher**.

### Build fails after upgrade

1. **Clean everything**:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   ```

2. **Delete Gradle cache** (if needed):
   ```bash
   rm -rf ~/.gradle/caches
   ```

3. **Rebuild**:
   ```bash
   flutter pub get
   flutter build apk
   ```

## Gradle Version Compatibility

| Gradle Version | Android Gradle Plugin | Java Version | Flutter Support |
|---------------|----------------------|--------------|----------------|
| 8.0 - 8.2     | 8.0.x                | Java 17+     | ✅ Yes         |
| 8.3           | 8.1.x                | Java 17+     | ✅ Yes         |
| 8.4 - 8.5     | 8.1.x - 8.2.x        | Java 17+     | ✅ Yes         |
| 8.6+          | 8.2.x+               | Java 17+     | ⚠️ Test first  |

## Quick Reference

**Current file location**:
```
/Users/darren/IdeaProjects/superstar_avatar/android/gradle/wrapper/gradle-wrapper.properties
```

**Current version**: 8.3

**Recommended upgrade**: 8.5

**File to edit**: `android/gradle/wrapper/gradle-wrapper.properties`

**Line to change**: 
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-all.zip
```

