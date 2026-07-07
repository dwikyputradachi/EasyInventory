# ============================================================
# ML Kit Text Recognition (google_mlkit_text_recognition)
# ============================================================
# PENTING: R8/ProGuard di release build (isMinifyEnabled = true) akan
# menghapus/mengacak kelas internal ML Kit yang dipakai lewat reflection
# kalau tidak ada -keep di sini. Tanpa ini, OCR bisa gagal SENYAP di APK
# release meskipun jalan normal di emulator/debug (karena debug build
# tidak di-minify).
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_bundled_common.** { *; }
-keep class com.google.android.gms.common.internal.** { *; }

-dontwarn com.google.mlkit.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ============================================================
# image_picker & mobile_scanner (kamera)
# ============================================================
# Beberapa plugin kamera mereferensikan CameraX lewat reflection.
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# ============================================================
# Google Play Services / Firebase (google-services plugin)
# ============================================================
# Jaga-jaga supaya login (Firebase Auth dkk, kalau dipakai) tidak ikut
# kena strip juga.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ============================================================
# General Flutter plugin safety net
# ============================================================
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }