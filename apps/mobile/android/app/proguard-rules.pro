# Habitat Production ProGuard & R8 Optimization Rules

# Flutter Wrapper & Embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Habitat Android Native Alarm & Service Components
-keep class com.habitat.app.MainActivity { *; }
-keep class com.habitat.app.NativeAlarmPlugin { *; }
-keep class com.habitat.app.AlarmReceiver { *; }
-keep class com.habitat.app.BootReceiver { *; }
-keep class com.habitat.app.AlarmForegroundService { *; }
-keep class com.habitat.app.** { *; }

# Kotlin Reflection & Coroutines
-keepattributes *Annotation*,InnerClasses,EnclosingMethod,Signature,Exceptions
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# AndroidX Core & Lifecycle
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.lifecycle.** { *; }
