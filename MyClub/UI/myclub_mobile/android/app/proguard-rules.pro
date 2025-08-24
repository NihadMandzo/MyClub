
# Stripe Push Provisioning is optional; suppress missing-class analysis.
-dontwarn com.stripe.android.pushprovisioning.**
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# Keep the proxy classes so R8 doesn't inline through them.
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }
