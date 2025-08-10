import 'dart:io';

/// Configuration helper for API endpoints based on platform
class ApiConfig {
  /// Get the appropriate base URL for the current platform
  static String get baseUrl {
    // Check if a custom baseUrl is provided via environment variables
    const envBaseUrl = String.fromEnvironment("baseUrl");
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    // Default API configuration based on platform
    if (Platform.isAndroid) {
      // For Android emulator: 10.0.2.2 maps to host machine's localhost
      return "http://10.0.2.2:5206/api/";
    } else if (Platform.isIOS) {
      // For iOS simulator: localhost works directly
      return "http://localhost:5206/api/";
    } else {
      // For other platforms (desktop, web), use localhost
      return "http://localhost:5206/api/";
    }
  }

  /// Get the login endpoint URL
  static String get loginUrl => "${baseUrl}Users/login";

  /// Get the users endpoint URL
  static String get usersUrl => "${baseUrl}Users/";

  /// Print current configuration for debugging
  static void printConfig() {
    print("=== API Configuration ===");
    print("Platform: ${Platform.operatingSystem}");
    print("Base URL: $baseUrl");
    print("Login URL: $loginUrl");
    print("========================");
  }

  /// Check if running on physical device vs emulator/simulator
  static bool get isEmulator {
    // This is a simplified check - in production you might want more sophisticated detection
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Alternative URLs for different environments
  static const String localHostUrl = "http://localhost:5206/api/";
  static const String androidEmulatorUrl = "http://10.0.2.2:5206/api/";
  static const String productionUrl = "https://your-api.com/api/"; // Replace with actual production URL
}
