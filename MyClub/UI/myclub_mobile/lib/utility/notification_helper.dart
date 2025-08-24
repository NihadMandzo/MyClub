import 'package:flutter/material.dart';

/// Helper class for showing notifications, dialogs, and snackbars
class NotificationHelper {
  /// Extract a clean, user-friendly message from any error/exception
  static String extractErrorMessage(Object error) {
    String msg = error.toString();
    // Remove common wrappers/prefixes
    msg = msg.replaceFirst(RegExp(r'^Exception:\s*'), '');
    msg = msg.replaceFirst(RegExp(r'^Greška:\s*'), '');
    // If a generic prefix like "Greška pri ...: " exists, prefer the part after the last colon
    if (RegExp(r'Greška|Error', caseSensitive: false).hasMatch(msg) && msg.contains(':')) {
      msg = msg.split(':').last.trim();
    }
    if (msg.startsWith('API Error')) {
      msg = 'Došlo je do greške. Pokušajte ponovo.';
    }
    return msg;
  }

  /// Show API error using only the message from the exception/object
  static void showApiError(BuildContext context, Object error) {
    showError(context, extractErrorMessage(error));
  }
  /// Calculate safe margin for floating SnackBars
  static EdgeInsets _getSafeSnackBarMargin(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // For very small screens, use less bottom margin
    final bottomMargin = screenHeight < 600 ? 60 : 80;
    
    return EdgeInsets.only(
      bottom: bottomPadding + bottomMargin,
      left: 16,
      right: 16,
    );
  }

  /// Determine if we should use floating behavior based on screen size
  static SnackBarBehavior _getSnackBarBehavior(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Use fixed behavior for very small screens to avoid layout issues
    return screenHeight < 600 ? SnackBarBehavior.fixed : SnackBarBehavior.floating;
  }
  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    final behavior = _getSnackBarBehavior(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: behavior,
        margin: behavior == SnackBarBehavior.floating ? _getSafeSnackBarMargin(context) : null,
        shape: behavior == SnackBarBehavior.floating ? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ) : null,
      ),
    );
  }

  /// Show an error snackbar
  static void showError(BuildContext context, String message) {
    // Sanitize message to avoid technical prefixes
    String cleanMessage = message;
    if (cleanMessage.startsWith('Exception: ')) {
      cleanMessage = cleanMessage.replaceFirst('Exception: ', '');
    }
    if (cleanMessage.startsWith('Greška: ')) {
      cleanMessage = cleanMessage.replaceFirst('Greška: ', '');
    }
    if (cleanMessage.startsWith('API Error')) {
      // Keep it short and user-friendly
      cleanMessage = 'Došlo je do greške. Pokušajte ponovo.';
    }
    final behavior = _getSnackBarBehavior(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cleanMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: behavior,
        margin: behavior == SnackBarBehavior.floating ? _getSafeSnackBarMargin(context) : null,
        shape: behavior == SnackBarBehavior.floating ? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ) : null,
      ),
    );
  }

  /// Show an info snackbar
  static void showInfo(BuildContext context, String message) {
    final behavior = _getSnackBarBehavior(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: behavior,
        margin: behavior == SnackBarBehavior.floating ? _getSafeSnackBarMargin(context) : null,
        shape: behavior == SnackBarBehavior.floating ? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ) : null,
      ),
    );
  }

  /// Create a properly configured SnackBar with safe margins and responsive behavior
  static SnackBar createSnackBar({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final behavior = _getSnackBarBehavior(context);
    return SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: behavior,
      margin: behavior == SnackBarBehavior.floating ? _getSafeSnackBarMargin(context) : null,
      shape: behavior == SnackBarBehavior.floating ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ) : null,
    );
  }

  /// Show a warning snackbar
  static void showWarning(BuildContext context, String message) {
    final behavior = _getSnackBarBehavior(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: behavior,
        margin: behavior == SnackBarBehavior.floating ? _getSafeSnackBarMargin(context) : null,
        shape: behavior == SnackBarBehavior.floating ? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ) : null,
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    Color confirmButtonColor = Colors.blue,
    String confirmText = 'Potvrdi',
    String cancelText = 'Otkaži',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmButtonColor,
                foregroundColor: Colors.white
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  /// Show an info dialog
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'U redu',
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  /// Show an error dialog
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'U redu',
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  /// Show a loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Hide the currently showing dialog
  static void hideDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show a bottom sheet with custom content
  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => child,
    );
  }
}
