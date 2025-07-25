import 'package:flutter/material.dart';

class FormDialogUtility {
  /// Shows a dialog for adding or editing a color
  static Future<Map<String, dynamic>?> showColorDialog(
    BuildContext context, {
    String? name,
    String? hexCode,
    bool isEdit = false,
  }) async {
    final nameController = TextEditingController(text: name);
    final hexCodeController = TextEditingController(text: hexCode);

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Izmijeni boju' : 'Dodaj novu boju'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv boje',
                  hintText: 'npr., Kraljevska plava',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: hexCodeController,
                decoration: const InputDecoration(
                  labelText: 'Hex Color Code',
                  hintText: 'npr., #4285F4',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    hexCodeController.text.isNotEmpty) {
                  Navigator.of(context).pop({
                    'name': nameController.text,
                    'hexCode': hexCodeController.text,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Molimo popunite sva polja')),
                  );
                }
              },
              child: Text(isEdit ? 'Sačuvaj' : 'Dodaj'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog for adding or editing a category
  static Future<Map<String, dynamic>?> showCategoryDialog(
    BuildContext context, {
    String? name,
    String? description,
    bool isEdit = false,
  }) async {
    final nameController = TextEditingController(text: name);
    final descriptionController = TextEditingController(text: description);

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Izmijeni kategoriju' : 'Dodaj novu kategoriju'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv kategorije',
                  hintText: 'npr., Sportska oprema',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  hintText: 'Kratak opis kategorije',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.of(context).pop({
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'isActive': true,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Naziv kategorije je obavezan'),
                    ),
                  );
                }
              },
              child: Text(isEdit ? 'Sačuvaj' : 'Dodaj'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog for adding or editing a size
  static Future<String?> showSizeDialog(
    BuildContext context, {
    String? name,
    bool isEdit = false,
  }) async {
    final nameController = TextEditingController(text: name);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Izmijeni veličinu' : 'Dodaj novu veličinu'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Naziv veličine',
              hintText: 'npr., XXL, 46, Velika',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.of(context).pop(nameController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naziv veličine je obavezan')),
                  );
                }
              },
              child: Text(isEdit ? 'Sačuvaj' : 'Dodaj'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog for deleting an item
  static Future<bool> showDeleteConfirmationDialog(
    BuildContext context, {
    required String itemType,
    required String itemName,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Potvrdi brisanje'),
              content: Text(
                'Da li ste sigurni da želite obrisati $itemType "$itemName"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Otkaži'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Obriši'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
