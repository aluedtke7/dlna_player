# shared_preferences_android 2.5 talks to its Kotlin code via JNI (package jni),
# which looks classes and methods up by name. R8 strips or renames them in
# release builds, loading the preferences then fails (e.g. the visited servers
# are lost) with NoSuchMethodError / ClassNotFoundException.
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Kotlin types the jni package references by name for suspend functions.
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
