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
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
  }

  /// Shows an alert dialog with customizable title and message.
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(buttonLabel),
            ),
          ],
        );
      },
    );
  }

  /// Shows an error dialog with a red title.
  static Future<void> showError(
    BuildContext context, {
    String title = 'Error',
    required String message,
    String buttonLabel = 'OK',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(color: Colors.red),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(buttonLabel),
            ),
          ],
        );
      },
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: content,
          actions: actions,
        );
      },
    );
  }
}

