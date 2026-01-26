#!/bin/bash
set -euo pipefail

# Usage:
# ./export_from_archive.sh /path/to/YourApp.xcarchive ad-hoc /path/to/cert.p12 P12_PASSWORD /path/to/profile.mobileprovision
# The script imports the cert into a temporary keychain, installs the provisioning profile,
# runs xcodebuild -exportArchive with the matching ExportOptions plist, and cleans up.

ARCHIVE_PATH="$1"
METHOD="$2" # ad-hoc or app-store
P12_PATH="$3" # path to .p12 (can be empty string to skip importing)
P12_PASSWORD="$4"
PROVISIONING_PROFILE_PATH="$5" # optional

if [ ! -f "$ARCHIVE_PATH" ]; then
  echo "Archive not found at $ARCHIVE_PATH"
  exit 2
fi

EXPORT_DIR="$(pwd)/exported_ipa_$(date +%s)"
mkdir -p "$EXPORT_DIR"

KEYCHAIN_NAME="export.keychain"
KEYCHAIN_PASS="export-pass"

cleanup() {
  echo "Cleaning up: deleting keychain if present"
  security delete-keychain "$KEYCHAIN_NAME" || true
}
trap cleanup EXIT

if [ -n "$P12_PATH" ] && [ -f "$P12_PATH" ]; then
  echo "Creating temporary keychain and importing certificate"
  security create-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN_NAME"
  security import "$P12_PATH" -k ~/Library/Keychains/$KEYCHAIN_NAME -P "$P12_PASSWORD" -A || true
  security list-keychains -s ~/Library/Keychains/$KEYCHAIN_NAME
  security unlock-keychain -p "$KEYCHAIN_PASS" ~/Library/Keychains/$KEYCHAIN_NAME
fi

if [ -n "$PROVISIONING_PROFILE_PATH" ] && [ -f "$PROVISIONING_PROFILE_PATH" ]; then
  echo "Installing provisioning profile"
  mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
  cp "$PROVISIONING_PROFILE_PATH" ~/Library/MobileDevice/Provisioning\ Profiles/
fi

if [ "$METHOD" = "app-store" ]; then
  PLIST="$(dirname "$0")/ExportOptions-AppStore.plist"
else
  PLIST="$(dirname "$0")/ExportOptions-AdHoc.plist"
fi

echo "Exporting archive to $EXPORT_DIR using $PLIST"
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportPath "$EXPORT_DIR" -exportOptionsPlist "$PLIST"

echo "Export completed. Artifacts in: $EXPORT_DIR"
ls -la "$EXPORT_DIR"
