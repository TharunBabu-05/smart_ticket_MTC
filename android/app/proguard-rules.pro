# Razorpay ProGuard Rules
-keep class com.razorpay.** { *; }
-keep class proguard.annotation.** { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep *;
    @proguard.annotation.KeepClassMembers *;
}

# Firebase Rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Location Services
-keep class com.google.android.gms.location.** { *; }

# Sensors
-keep class com.sensors.**  { *; }

# General Android Rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# R8 compatibility
-dontwarn proguard.annotation.**
-dontwarn com.razorpay.**
