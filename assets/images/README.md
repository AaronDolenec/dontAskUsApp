# Image Assets

Place your app images here.

## Recommended Structure

```
images/
├── illustrations/
│   ├── onboarding_1.png
│   ├── onboarding_2.png
│   └── onboarding_3.png
├── icons/
│   ├── custom_icon.svg
│   └── badge.png
└── backgrounds/
    └── pattern.png
```

## Usage in Code

```dart
Image.asset('assets/images/illustrations/onboarding_1.png')
```

## Image Optimization Tips

1. **Use WebP format** when possible for smaller file sizes
2. **Provide multiple resolutions** (1x, 2x, 3x) for different screen densities
3. **Compress images** before adding to the project
4. **Use SVG** for icons and simple graphics when possible

## Resolution Variants

For density-aware images, structure as:
```
images/
├── logo.png        (1x - baseline)
├── 2.0x/
│   └── logo.png    (2x)
└── 3.0x/
    └── logo.png    (3x)
```

Flutter will automatically select the appropriate resolution.
