import 'package:flutter/material.dart';

class CategoryDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final bool isEdit;

  const CategoryDialog({
    Key? key, 
    this.initialName,
    this.initialDescription,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();

  /// Shows a dialog for adding or editing a category
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? name,
    String? description,
    bool isEdit = false,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true, // Allow dialog to be dismissed when tapping outside
      barrierColor: Colors.black54, // Semi-transparent barrier
      useRootNavigator: false, // Set to false to match DialogUtility behavior
      builder: (BuildContext dialogContext) {
        return CategoryDialog(
          initialName: name,
          initialDescription: description,
          isEdit: isEdit,
        );
      },
    );
  }
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Izmijeni kategoriju' : 'Dodaj novu kategoriju'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv kategorije',
                hintText: 'npr., Sportska oprema',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Opis',
                hintText: 'Kratak opis kategorije',
              ),
              maxLines: 3,
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
                const SnackBar(content: Text('Naziv kategorije je obavezan')),
              );
              return;
            }
            Navigator.of(context).pop({
              'name': _nameController.text,
              'description': _descriptionController.text,
              'isActive': true,
            });
          },
          child: Text(widget.isEdit ? 'Sačuvaj' : 'Dodaj'),
        ),
      ],
    );
  }
}
