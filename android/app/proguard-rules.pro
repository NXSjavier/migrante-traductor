# R8 / ProGuard rules for Migrante Traductor.
#
# Release builds currently run with isMinifyEnabled = false because R8 full
# mode removes ML Kit classes that are instantiated through reflection.
# These rules are kept so minification can be re-enabled safely later.

# ML Kit resolves translators and model managers through LazyInstanceMap,
# so their constructors must survive shrinking and obfuscation.
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keepclassmembers class com.google.mlkit.** { public <init>(...); }

# Internal Google Play Services implementation of the ML Kit pipeline.
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keepclassmembers class com.google.android.gms.internal.mlkit_** { public <init>(...); }

# Text recognition ships a single entry point that references the optional
# script recognizers. This app only uses Latin, so those classes are absent.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
