# App Icon Assets

Place your app icon files here:

## Required Files

### Main Icon
- `app_icon.png` - 1024x1024px PNG, no transparency for iOS, can have rounded corners

### Adaptive Icon (Android)
- `app_icon_foreground.png` - 432x432px PNG with transparency, the actual icon should be centered in a 288x288 safe zone

## Generating Icons

After placing your icon files, run:

```bash
flutter pub get
dart run flutter_launcher_icons
```

## Icon Design Guidelines

### iOS
- No transparency
- Don't include rounded corners (iOS adds them automatically)
- Use the full 1024x1024 canvas

### Android
- Use adaptive icon format
- Foreground: 432x432 with safe zone of 288x288 centered
- Background color is set to #6366F1 (primary color) in pubspec.yaml

## Temporary Placeholder

Until you create custom icons, the app will use the default Flutter icon.
