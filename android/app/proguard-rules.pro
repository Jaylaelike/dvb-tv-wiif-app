# ----------------------------------------------------------
# FIX FOR BUILD ERRORS (Play Store Deferred Components)
# ----------------------------------------------------------
# These classes are referenced by Flutter internally but are often missing
# if you aren't using Dynamic Features. Ignoring them allows the build to finish.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ----------------------------------------------------------
# YOUR EXISTING RULES
# ----------------------------------------------------------

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Sound
-keep class com.dooboolab.** { *; }
-keep interface com.dooboolab.** { *; }

# Socket.IO
-keep class io.socket.** { *; }
-keep interface io.socket.** { *; }
-keep class org.json.** { *; }

# Audio Native
-keep class android.media.** { *; }
-keepclassmembers class android.media.** { *; }

# Prevent obfuscation of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep generic signature of Call, Response (R8 full mode strips signatures from non-kept items)
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response

# With R8 full mode generic signatures are stripped for classes that are not
# kept. Suspend functions are wrapped in continuations where the type argument
# is used.
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation