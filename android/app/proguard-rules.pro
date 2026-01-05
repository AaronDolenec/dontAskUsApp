# Keep Flutter's classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Riverpod generated code
-keep class ** extends riverpod.ProviderBase { *; }

# Keep serialization classes
-keepattributes *Annotation*
-keepattributes Signature

# Keep JSON serialization
-keep class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep http client classes
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**
-dontwarn android.net.http.**

# Keep secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep connectivity plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Keep shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep QR Flutter
-keep class net.glxn.qrgen.** { *; }

# Keep web socket channel
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Keep fl_chart
-keep class com.github.nicemr.** { *; }

# Optimization
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
