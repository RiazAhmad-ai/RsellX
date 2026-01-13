# ML Kit Text Recognition ProGuard Rules
# Keep ML Kit optional language models (even if not used)

-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep all ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Google Play Services
-keep class com.google.android.gms.internal.** { *; }
-dontwarn com.google.android.gms.**

# Camera
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Hive Database
-keep class * extends hive.HiveObject
-keep class hive.** { *; }
-keepclassmembers class * extends hive.HiveObject {
  <fields>;
}
