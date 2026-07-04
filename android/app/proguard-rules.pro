# ── ProGuard / R8 keep rules for the release build ──────────────────────────
# Most Flutter plugins ship their own consumer rules; the entries below cover
# the libraries that need explicit keeps (reflection / JS bridges) so R8's
# shrinking doesn't strip classes they look up at runtime.

# Razorpay: uses a JavaScript interface + reflection for the checkout flow and
# will crash if obfuscated without these rules.
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Play Core / SplitCompat — referenced by the Flutter embedding's deferred
# components hooks even when the app doesn't use them.
-dontwarn com.google.android.play.core.**

# Firebase / Crashlytics keep their own generated rules; keep model/annotation
# metadata to preserve readable crash reports.
-keepattributes SourceFile,LineNumberTable
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
