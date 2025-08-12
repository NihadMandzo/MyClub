import 'dart:io';

/// Configuration helper for API endpoints based on platform
class ApiConfig {
  // Static variable to hold custom base URL
  static String? _customBaseUrl;
  
  /// Set a custom base URL at runtime
  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.endsWith('/') ? url : '$url/';
  }
  
  /// Clear custom base URL (revert to default behavior)
  static void clearCustomBaseUrl() {
    _customBaseUrl = null;
  }
  
  /// Get the appropriate base URL for the current platform
  static String get baseUrl {
    // 1. Check if custom URL is set at runtime
    if (_customBaseUrl != null) {
      return _customBaseUrl!;
    }
    
    // 2. Check if a custom baseUrl is provided via environment variables
    const envBaseUrl = String.fromEnvironment("baseUrl");
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl.endsWith('/') ? envBaseUrl : '$envBaseUrl/';
    }

    // 3. Default API configuration based on platform
    if (Platform.isAndroid) {
      // Try real device IP first, fallback to emulator IP
      // For real Android devices, use your computer's IP address
      // For Android emulator: 10.0.2.2 maps to host machine's localhost
      return "http://192.168.0.27:5206/api/";
    } else if (Platform.isIOS) {
      // For iOS simulator: localhost works directly
      return "http://localhost:5206/api/";
    } else {
      // For other platforms (desktop, web), use localhost
      return "http://localhost:5206/api/";
    }
  }

  /// Alternative method to detect if running on emulator vs real device
  static String getDeviceSpecificUrl() {
    if (Platform.isAndroid) {
      // You can add device-specific logic here if needed
      // For now, assume real device and use the computer's IP
      return "http://192.168.0.27:5206/api/";
    }
    return baseUrl;
  }

  /// Get the login endpoint URL
  static String get loginUrl => "${baseUrl}Users/login";

  /// Get the users endpoint URL
  static String get usersUrl => "${baseUrl}Users/";

  /// Print current configuration for debugging
  static void printConfig() {
    print("=== API Configuration ===");
    print("Platform: ${Platform.operatingSystem}");
    print("Custom URL: ${_customBaseUrl ?? 'Not set'}");
    print("Environment URL: ${const String.fromEnvironment("baseUrl").isEmpty ? 'Not set' : const String.fromEnvironment("baseUrl")}");
    print("Active Base URL: $baseUrl");
    print("Login URL: $loginUrl");
    print("========================");
  }

  /// Quick setup methods for common configurations
  static void useEmulator() {
    setCustomBaseUrl("http://10.0.2.2:5206/api/");
  }
  
  static void useLocalDevice(String ipAddress) {
    setCustomBaseUrl("http://$ipAddress:5206/api/");
  }
  
  static void useLocalhost() {
    setCustomBaseUrl("http://localhost:5206/api/");
  }

  /// Check if running on physical device vs emulator/simulator
  static bool get isEmulator {
    // This is a simplified check - in production you might want more sophisticated detection
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Alternative URLs for different environments
  static const String localHostUrl = "http://localhost:5206/api/";
  static const String androidEmulatorUrl = "http://10.0.2.2:5206/api/";
}
