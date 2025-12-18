## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## RevenueCat
-keep class com.revenuecat.purchases.** { *; }

## Google Sign In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

## Google Play Core (for deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

## Ignore warnings about missing classes
-dontwarn com.google.android.play.core.**
-ignorewarnings
