# Flutter's AOT compiled Dart code doesn't need ProGuard rules.
# Keep any plugin classes that might be accessed via reflection.
-keep class io.flutter.** { *; }
