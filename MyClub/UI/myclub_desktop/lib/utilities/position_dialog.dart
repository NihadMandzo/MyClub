import 'package:flutter/material.dart';

class PositionDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? name,
    bool? isPlayer,
    bool isEdit = false,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: name ?? '');
    bool isPlayerValue = isPlayer ?? true;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Uredi poziciju' : 'Dodaj novu poziciju'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv pozicije',
                    border: OutlineInputBorder(),
                    hintText: 'npr. Golman, Napadač, Trener',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite naziv pozicije';
                    }
                    if (value.trim().length > 50) {
                      return 'Naziv ne može biti duži od 50 znakova';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Pozicija za igrača'),
                  subtitle: const Text('Uklonite ako je pozicija za trenera ili drugo osoblje'),
                  value: isPlayerValue,
                  onChanged: (bool? value) {
                    setState(() {
                      isPlayerValue = value ?? true;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
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
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'name': nameController.text.trim(),
                    'isPlayer': isPlayerValue,
                  });
                }
              },
              child: Text(isEdit ? 'Spremi' : 'Dodaj'),
            ),
          ],
        ),
      ),
    );
  }
}
