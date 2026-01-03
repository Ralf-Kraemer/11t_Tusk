#!/bin/bash
set -e  # Exit immediately if any command fails
# OS Detection
OS_TYPE="$(uname)"
IS_WINDOWS=false
if [[ "$OS_TYPE" == *"MINGW"* || "$OS_TYPE" == *"MSYS"* || "$OS_TYPE" == *"CYGWIN"* ]]; then
  IS_WINDOWS=true
fi
# Git Bash/WSL Warning for Windows users
if [ "$IS_WINDOWS" = true ]; then
  echo ""
  echo "⚠️  Windows Detected!"
  echo "🔔 IMPORTANT: Please run this script inside Git Bash or WSL."
  echo "❌ It will NOT work correctly in normal Command Prompt (cmd.exe) or PowerShell."
  echo "✅ If you don't have Git Bash installed, get it from https://gitforwindows.org/"
  echo ""
fi
echo ""
echo "🚀 Welcome to the Flutter Project Branding Setup Wizard!"
echo "💬 This will update your project name, package name, app icon, and clean imports."
echo ""
# Helper function for reading input
read_input() {
  if [ "$IS_WINDOWS" = true ]; then
    read -p "$1" value
  else
    read -rp "$1" value
  fi
  echo "$value"
}
# Extract old app name from pubspec.yaml
oldAppName=$(grep '^name:' pubspec.yaml | awk '{print $2}')
# Extract old SDK version
oldSdkVersion=$(grep '^  sdk:' pubspec.yaml | awk '{print $2}')
# 1. Ask for new App Name
echo "📝 Step 1: App Name"
echo "Please enter your NEW Flutter project name."
echo "✅ Example: base_nest"
echo "Tip: Use only lowercase letters, numbers, and underscores (_) without spaces."
appName=$(read_input "App Name: ")
# 2. Ask for new Package Name
echo ""
echo "📝 Step 2: Package Name"
echo "Please enter your NEW Android/iOS package name (applicationId)."
echo "✅ Example: com.example.basenest"
echo "Tip: Use your domain in reverse + project name (no spaces, all lowercase)."
packageName=$(read_input "Package Name: ")
# 3. Ask for new App Icon path (optional)
echo ""
echo "📝 Step 3: App Icon"
echo "Optionally enter full path to your 512x512 PNG App Icon."
if [ "$IS_WINDOWS" = true ]; then
  echo "✅ Example (absolute path): C:/Users/YourName/Desktop/logo.png"
else
  echo "✅ Example (absolute path): /Users/yourname/Desktop/logo.png"
fi
echo "✅ Example (relative path): ./assets/images/base_logo.png"
echo "If you want to skip icon replacement, just press ENTER."
iconPath=$(read_input "App Icon Path: ")
# 4. Update pubspec.yaml (App Name)
echo ""
echo "📄 Step 4: Updating pubspec.yaml..."
if [ -f pubspec.yaml ]; then
  sed -i.bak "s/^name: .*/name: ${appName}/" pubspec.yaml
  echo "✅ App name updated to '$appName' in pubspec.yaml."
else
  echo "❌ Error: pubspec.yaml not found! Are you inside the project root?"
  exit 1
fi
# 5. Add environment SDK constraint if missing if missing if missing
if ! grep -q "environment:" pubspec.yaml; then
  echo "🔧 Adding environment SDK constraint (>= Dart 3.7.0)..."
  echo -e "\nenvironment:\n  sdk: '^3.7.0'" >> pubspec.yaml
else
  echo "✅ SDK constraint already exists. (Version: $oldSdkVersion)"
fi
# 5.1 Update all imports
echo ""
echo "🛠 Step 5.1: Updating all Dart imports from 'package:$oldAppName/' to 'package:$appName/'..."
find ./lib -type f -name "*.dart" -print0 | xargs -0 sed -i.bak "s/package:${oldAppName}\//package:${appName}\//g"
echo "✅ All Dart imports updated."
# 5.2 Update AndroidManifest.xml label
echo ""
echo "🛠 Step 5.2: Updating app label in AndroidManifest.xml..."
sed -i.bak "s/android:label=\"[^\"]*\"/android:label=\"${appName}\"/" android/app/src/main/AndroidManifest.xml
echo "✅ AndroidManifest app label updated."
# 6. Replace App Icon if provided
echo ""
if [ ! -z "$iconPath" ]; then
  if [ "$IS_WINDOWS" = true ]; then
    iconPath=$(cygpath "$iconPath")
  else
    iconPath=$(realpath "$iconPath")
  fi
  if [ -f "$iconPath" ]; then
    echo "🎨 Step 6: Replacing app icon..."
    mkdir -p assets/icons
    cp "$iconPath" assets/icons/app_icon.png
    echo "✅ New app icon copied to assets/icons/app_icon.png."
  else
    echo "⚠️  Warning: Provided app icon path not found. Skipping icon replacement."
  fi
else
  echo "ℹ️  No new app icon provided. Keeping existing app icon."
fi
# 7. Update package name
echo ""
echo "📦 Step 7: Updating Android/iOS package name..."
flutter pub get
flutter pub run change_app_package_name:main "$packageName"
echo "✅ Package name updated."
# 8. Generate app icons
echo ""
echo "🎨 Step 8: Generating launcher icons..."
flutter pub run flutter_launcher_icons
echo "✅ Launcher icons generated."
# 9. Final pub get
echo ""
echo "🔄 Step 9: Final flutter pub get..."
flutter pub get
echo "✅ Flutter dependencies updated."
# 10. Cleanup temp files
echo ""
echo "🧹 Cleaning temporary backup files..."
find ./lib -type f -name "*.bak" -delete
rm -f pubspec.yaml.bak
rm -f android/app/src/main/AndroidManifest.xml.bak
echo "✅ Cleanup done."
# 11. Finish
echo ""
echo "🎉 Setup completed successfully!"
echo "🚀 Your project is now fully rebranded!"
echo ""
read -rp "🎯 Press [ENTER] to exit..."
