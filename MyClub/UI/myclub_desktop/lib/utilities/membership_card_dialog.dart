import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:myclub_desktop/models/membership_card.dart';
import 'package:intl/intl.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';

class MembershipCardDialog extends StatefulWidget {
  final MembershipCardForm? initialData;
  final bool isEdit;

  const MembershipCardDialog({
    Key? key,
    this.initialData,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<MembershipCardDialog> createState() => _MembershipCardDialogState();

  /// Shows a dialog for adding or editing a membership campaign
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    MembershipCardForm? initialData,
    bool isEdit = false,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      useRootNavigator: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
              child: MembershipCardDialog(
                initialData: initialData,
                isEdit: isEdit,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MembershipCardDialogState extends State<MembershipCardDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetGoalController;
  late TextEditingController _priceController;
  late TextEditingController _benefitsController;
  
  int _selectedYear = DateTime.now().year;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _initialImageUrl;
  String? _selectedImageName;
  bool _keepExistingImage = true;
  
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    
    // Generate year options (current year + 5 future years)
    final currentYear = DateTime.now().year;
    _availableYears = List.generate(6, (index) => currentYear + index);
    
    // Initialize controllers
    _nameController = TextEditingController(text: widget.initialData?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initialData?.description ?? '');
    _targetGoalController = TextEditingController(
        text: widget.initialData?.targetMembers?.toString() ?? '');
    _priceController = TextEditingController(
        text: widget.initialData?.price?.toString() ?? '');
    _benefitsController = TextEditingController(text: widget.initialData?.benefits ?? '');
    
    // Set initial values if editing
    if (widget.initialData != null) {
      _selectedYear = widget.initialData!.year ?? DateTime.now().year;
      _startDate = widget.initialData!.startDate ?? DateTime.now();
      _endDate = widget.initialData!.endDate;
      _initialImageUrl = widget.initialData!.image is String ? widget.initialData!.image : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetGoalController.dispose();
    _priceController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.bytes != null) {
          // Web or direct bytes access
          setState(() {
            _imageBytes = file.bytes;
            _selectedImageName = file.name;
            _keepExistingImage = false;
            
            NotificationUtility.showSuccess(
              context,
              message: 'Image successfully selected',
            );
          });
        } else if (file.path != null) {
          // Desktop platforms
          final fileBytes = await File(file.path!).readAsBytes();
          setState(() {
            _imageFile = File(file.path!);
            _imageBytes = fileBytes;
            _selectedImageName = file.name;
            _keepExistingImage = false;
            
            NotificationUtility.showSuccess(
              context,
              message: 'Image successfully selected',
            );
          });
        }
      }
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Error selecting image: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with padding to account for close button
                  Padding(
                    padding: const EdgeInsets.only(right: 40.0),
                    child: Text(
                      widget.isEdit ? 'Edit Membership Campaign' : 'Start New Campaign',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Form content in scrollable area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
              // Year dropdown
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                value: _selectedYear,
                items: _availableYears.map((year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Campaign name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Campaign Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a campaign name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Target goal
              TextFormField(
                controller: _targetGoalController,
                decoration: const InputDecoration(
                  labelText: 'Target Goal',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 9823',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target goal';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Start Date
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(DateTime.now().year - 1),
                    lastDate: DateTime(DateTime.now().year + 5),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _startDate = pickedDate;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                ),
              ),
              const SizedBox(height: 16),
              
              // End Date (Optional)
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 10),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _endDate = pickedDate;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date (Optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _endDate = null;
                              });
                            },
                          ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                  child: Text(_endDate != null
                      ? DateFormat('yyyy-MM-dd').format(_endDate!)
                      : 'Not specified'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Benefits
              TextFormField(
                controller: _benefitsController,
                decoration: const InputDecoration(
                  labelText: 'Benefits',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Image upload
              const Text('Membership Card Design:'),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              
              if (widget.isEdit && _initialImageUrl != null)
                Row(
                  children: [
                    Checkbox(
                      value: _keepExistingImage,
                      onChanged: (value) {
                        setState(() {
                          _keepExistingImage = value!;
                        });
                      },
                    ),
                    const Text('Keep existing image if no new one is selected'),
                  ],
                ),
            ],
          ),
        ),
      ),
                  ),
                  
                  // Action buttons at the bottom
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final result = {
                              'year': _selectedYear,
                              'name': _nameController.text,
                              'description': _descriptionController.text,
                              'targetMembers': int.tryParse(_targetGoalController.text) ?? 0,
                              'price': double.tryParse(_priceController.text) ?? 0.0,
                              'startDate': _startDate.toIso8601String(),
                              'endDate': _endDate?.toIso8601String(),
                              'benefits': _benefitsController.text,
                              'keepPicture': _keepExistingImage,
                            };
                            
                            // Add image data if available
                            if (_imageBytes != null) {
                              result['imageBytes'] = _imageBytes;
                              result['fileName'] = _selectedImageName ?? _imageFile?.path.split('/').last ?? 'membership_card.jpg';
                            } else if (_initialImageUrl != null && _keepExistingImage) {
                              result['imageUrl'] = _initialImageUrl;
                            }
                            
                            Navigator.of(context).pop(result);
                          }
                        },
                        child: Text(widget.isEdit ? 'Update Campaign' : 'Start Campaign'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Close button in top right corner
            Positioned(
              top: 12.0,
              right: 12.0,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      // Show selected image from bytes
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
      );
    } else if (_initialImageUrl != null && _keepExistingImage) {
      // Show existing image from URL
      return Image.network(
        _initialImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                Text('Error loading image'),
              ],
            ),
          );
        },
      );
    } else {
      // Show placeholder
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 48),
            SizedBox(height: 8),
            Text('Click to upload membership card design'),
          ],
        ),
      );
    }
  }
}
