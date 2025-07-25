import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorDialog extends StatefulWidget {
  final String? initialName;
  final String? initialHexCode;
  final bool isEdit;

  const ColorDialog({
    Key? key,
    this.initialName,
    this.initialHexCode,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<ColorDialog> createState() => _ColorDialogState();

  /// Shows a dialog for adding or editing a color
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? name,
    String? hexCode,
    bool isEdit = false,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true, // Allow dialog to be dismissed when tapping outside
      barrierColor: Colors.black54, // Semi-transparent barrier
      useRootNavigator: false, // Set to false to match DialogUtility behavior
      builder: (BuildContext dialogContext) {
        return ColorDialog(
          initialName: name,
          initialHexCode: hexCode,
          isEdit: isEdit,
        );
      },
    );
  }
}

class _ColorDialogState extends State<ColorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _hexCodeController;
  late Color _pickerColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _hexCodeController = TextEditingController(text: widget.initialHexCode ?? '#4285F4');
    
    // Parse the hex color
    _pickerColor = Color(0xFF4285F4); // Default color (Google Blue)
    try {
      if (widget.initialHexCode != null && widget.initialHexCode!.isNotEmpty) {
        if (widget.initialHexCode!.startsWith('#') && widget.initialHexCode!.length == 7) {
          _pickerColor = Color(int.parse('0xFF${widget.initialHexCode!.substring(1)}'));
        }
      }
    } catch (e) {
      debugPrint('Error parsing color: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hexCodeController.dispose();
    super.dispose();
  }

  // Function to update selected color
  void _changeColor(Color color) {
    setState(() {
      _pickerColor = color;
      // Update hex code controller
      _hexCodeController.text = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Izmijeni boju' : 'Dodaj novu boju'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv boje',
                hintText: 'npr., Crvena, Plava',
              ),
            ),
            const SizedBox(height: 16),
            // Color picker
            ColorPicker(
              pickerColor: _pickerColor,
              onColorChanged: _changeColor,
              pickerAreaHeightPercent: 0.8,
              portraitOnly: true,
              displayThumbColor: true,
              enableAlpha: false,
              labelTypes: const [ColorLabelType.hex],
            ),
            const SizedBox(height: 8),
            // Hex code field
            TextField(
              controller: _hexCodeController,
              decoration: const InputDecoration(
                labelText: 'Hex Color Code',
                hintText: 'npr., #4285F4',
              ),
              onChanged: (value) {
                try {
                  if (value.startsWith('#') && value.length == 7) {
                    final color = Color(int.parse('0xFF${value.substring(1)}'));
                    if (color != _pickerColor) {
                      setState(() {
                        _pickerColor = color;
                      });
                    }
                  }
                } catch (e) {
                  debugPrint('Invalid color code: $e');
                }
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
            if (_nameController.text.isEmpty || _hexCodeController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Molimo popunite sva polja')),
              );
              return;
            }
            Navigator.of(context).pop({
              'name': _nameController.text,
              'hexCode': _hexCodeController.text,
            });
          },
          child: Text(widget.isEdit ? 'Sačuvaj' : 'Dodaj'),
        ),
      ],
    );
  }
}
