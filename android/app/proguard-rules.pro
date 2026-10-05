# ---------------------------------------------------------------- Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ---------------------------------------------------------------- FileVault
-keep class com.filevault.app.** { *; }

# ------------------------------------------------------------------ sqflite
-keep class com.tekartik.sqflite.** { *; }

# --------------------------------------------- Encrypted secure storage keys
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ------------------------------------------------------------------ biometric
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }

# ----------------------------------------------------------------- just_audio
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# ------------------------------------------------------------------ video/pdf
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class com.shockwave.** { *; }

# --------------------------------------------------- Desugaring + annotations
-dontwarn java.lang.invoke.StringConcatFactory
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
