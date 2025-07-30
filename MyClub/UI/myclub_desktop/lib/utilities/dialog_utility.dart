import 'package:flutter/material.dart';

/// A utility class to manage dialog interactions in the app.
/// Provides consistent methods for alerts, confirmations and error messages.
class DialogUtility {
  /// Shows a confirmation dialog with customizable title, message and button labels.
  /// Returns true if confirmed, false otherwise.
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Potvrdi',
    String cancelLabel = 'Otkaži',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      useRootNavigator: false, // Use false to keep current context active
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: confirmColor != null 
                ? TextButton.styleFrom(foregroundColor: confirmColor)
                : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    
    // Return false if dialog was dismissed
    return result ?? false;
  }
  
  /// Shows a delete confirmation dialog with a red delete button.
  /// Returns true if confirmed, false otherwise.
  static Future<bool> showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showConfirmation(
      context,
      title: title,
      message: message,
      confirmLabel: 'Izbriši',
      confirmColor: Colors.red,
    );
  }



  
  /// Shows a custom dialog with custom content and actions.
  /// This is useful for more complex dialogs like file pickers.
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      useRootNavigator: false, // Use false to keep current context active
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: content,
          actions: actions,
        );
      },
    );
  }
}

