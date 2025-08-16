import 'package:flutter/material.dart';

class CountryDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? name,
    String? code,
    bool isEdit = false,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: name ?? '');
    final codeController = TextEditingController(text: code ?? '');

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Uredi državu' : 'Dodaj novu državu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv države',
                  border: OutlineInputBorder(),
                  hintText: 'npr. Bosna i Hercegovina',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Molimo unesite naziv države';
                  }
                  if (value.trim().length > 50) {
                    return 'Naziv ne može biti duži od 50 znakova';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Kod države',
                  border: OutlineInputBorder(),
                  hintText: 'npr. BA, HR, RS',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Molimo unesite kod države';
                  }
                  if (value.trim().length != 2) {
                    return 'Kod države mora imati tačno 2 karaktera';
                  }
                  return null;
                },
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
                  'code': codeController.text.trim().toUpperCase(),
                });
              }
            },
            child: Text(isEdit ? 'Spremi' : 'Dodaj'),
          ),
        ],
      ),
    );
  }
}
