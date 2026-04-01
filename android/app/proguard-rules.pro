# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# AppLovin
-keep class com.applovin.** { *; }
-dontwarn com.applovin.**

# Google Play Billing
-keep class com.android.vending.billing.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
