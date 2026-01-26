Exporting a signed IPA from the CI-produced .xcarchive
=====================================================

This folder contains helper files to export a signed IPA from a `.xcarchive` on a Mac.

Files:
- ExportOptions-AppStore.plist — export options for App Store distribution
- ExportOptions-AdHoc.plist — export options for AdHoc/testing distribution
- export_from_archive.sh — script that imports certificates/profiles and runs export

Steps for the mac owner:
1. Download the `ios-build-output` artifact from the workflow run and extract it.
2. Locate the `.xcarchive` under the extracted `build/` tree (e.g. `build/ios/archive/Runner.xcarchive`).
3. Transfer your certificate (`.p12`) and provisioning profile (`.mobileprovision`) to the Mac.
4. Run the export script (example):

   ./export_from_archive.sh /path/to/Runner.xcarchive ad-hoc /path/to/cert.p12 "P12_PASSWORD" /path/to/profile.mobileprovision

5. The script will create `exported_ipa_<timestamp>/` with the `.ipa` inside.

Notes:
- The mac owner must have Xcode installed and be able to run `xcodebuild`.
- The script uses a temporary keychain and cleans up afterwards.
