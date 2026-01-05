# Splash Screen Assets

Place your splash screen assets here:

## Required Files

- `splash_logo.png` - Your app logo for the splash screen (recommended: 288x288px for Android 12+, or 768x768px for standard splash)

## Generating Splash Screen

After placing your splash logo, run:

```bash
flutter pub get
dart run flutter_native_splash:create
```

## Configuration

The splash screen is configured in `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#6366F1"
  image: "assets/splash/splash_logo.png"
  android: true
  ios: true
```

## Design Guidelines

- Use a transparent PNG for the logo
- Keep the logo simple and recognizable
- The background color (#6366F1) is the primary app color
- Logo should be visible on the primary color background

## Android 12+ Considerations

Android 12 introduced a new splash screen API:
- Maximum logo size: 288x288dp (scaled)
- Branding image is not supported
- Icon should be centered and will be masked to a circle or rounded rectangle

## Temporary Placeholder

Until you create custom splash assets, the app will use a solid color splash screen.
