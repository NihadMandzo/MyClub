import 'package:flutter/material.dart';

class SizeDialog extends StatelessWidget {
  final TextEditingController _nameController;
  final bool isEdit;

  SizeDialog({
    Key? key,
    String? initialName,
    this.isEdit = false,
  }) : _nameController = TextEditingController(text: initialName),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Izmijeni veličinu' : 'Dodaj novu veličinu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv veličine',
                hintText: 'npr., S, M, L, XL, 42, 44',
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Molimo unesite naziv veličine')),
              );
              return;
            }
            Navigator.of(context).pop(_nameController.text);
          },
          child: Text(isEdit ? 'Sačuvaj' : 'Dodaj'),
        ),
      ],
    );
  }

  /// Shows a dialog for adding or editing a size
  static Future<String?> show(
    BuildContext context, {
    String? name,
    bool isEdit = false,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true, // Allow dialog to be dismissed when tapping outside
      barrierColor: Colors.black54, // Semi-transparent barrier
      useRootNavigator: false, // Use false to keep current context active - like DialogUtility
      builder: (BuildContext dialogContext) {
        return SizeDialog( // Simplify - no need for PopScope
          initialName: name,
          isEdit: isEdit,
        );
      },
    );
  }
}
