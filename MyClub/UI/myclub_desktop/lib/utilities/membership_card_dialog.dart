import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:myclub_desktop/models/membership_card.dart';
import 'package:intl/intl.dart';
import 'package:myclub_desktop/providers/membership_card_provider.dart';
import 'package:myclub_desktop/utilities/dialog_utility.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';

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
  
  /// Creates a new campaign
  static Future<bool> createCampaign(BuildContext context) async {
    final result = await show(
      context,
      initialData: MembershipCardForm(
        year: DateTime.now().year,
        startDate: DateTime.now(),
        isActive: true,
      ),
    );
    
    if (result != null) {
      try {
        final provider = Provider.of<MembershipCardProvider>(context, listen: false);
        
        // Handle image upload if present
        if (result.containsKey('imageBytes') && result.containsKey('fileName')) {
          await provider.insertWithImage(
            result, 
            result['imageBytes'], 
            result['fileName']
          );
        } else {
          await provider.insert(result);
        }
        
        NotificationUtility.showSuccess(
          context,
          message: 'Campaign created successfully',
        );
        
        return true;
      } catch (e) {
        NotificationUtility.showError(
          context,
          message: 'Failed to create campaign: ${e.toString()}',
        );
        return false;
      }
    }
    
    return false;
  }
  
  /// Edits an existing campaign
  static Future<bool> editCampaign(BuildContext context, MembershipCard campaign) async {
    final result = await show(
      context,
      initialData: MembershipCardForm(
        year: campaign.year,
        name: campaign.name,
        description: campaign.description,
        targetMembers: campaign.targetMembers,
        price: campaign.price,
        startDate: campaign.startDate,
        endDate: campaign.endDate,
        benefits: campaign.benefits,
        image: campaign.imageUrl,
        isActive: campaign.isActive,
      ),
      isEdit: true,
    );
    
    if (result != null) {
      // Ask for confirmation before updating
      final confirm = await DialogUtility.showConfirmation(
        context, 
        title: 'Update Campaign',
        message: 'Are you sure you want to save changes to ${campaign.name}?',
      );
      
      if (!confirm) return false;
      
      try {
        final provider = Provider.of<MembershipCardProvider>(context, listen: false);
        
        // Handle image upload if present
        if (result.containsKey('imageBytes') && result.containsKey('fileName')) {
          await provider.updateWithImage(
            campaign.id,
            result, 
            result['imageBytes'], 
            result['fileName']
          );
        } else {
          await provider.update(campaign.id, result);
        }
        
        NotificationUtility.showSuccess(
          context,
          message: 'Campaign updated successfully',
        );
        
        return true;
      } catch (e) {
        NotificationUtility.showError(
          context,
          message: 'Failed to update campaign: ${e.toString()}',
        );
        return false;
      }
    }
    
    return false;
  }
  
  /// Deletes an existing campaign
  static Future<bool> deleteCampaign(BuildContext context, MembershipCard campaign) async {
    final shouldDelete = await DialogUtility.showDeleteConfirmation(
      context, 
      title: 'Delete Campaign',
      message: 'Are you sure you want to delete the campaign "${campaign.name}"? This action cannot be undone.',
    );
    
    if (!shouldDelete) return false;
    
    try {
      final provider = Provider.of<MembershipCardProvider>(context, listen: false);
      await provider.delete(campaign.id);
      
      NotificationUtility.showSuccess(
        context,
        message: 'Campaign deleted successfully',
      );
      
      return true;
    } catch (e) {
      NotificationUtility.showError(
        context,
        message: 'Failed to delete campaign: ${e.toString()}',
      );
      return false;
    }
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
    
    // Generate year options (current year + 5 future years + past 2 years)
    final currentYear = DateTime.now().year;
    _availableYears = List.generate(8, (index) => currentYear - 2 + index);
    
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
      // Make sure the selected year is in the available years list
      if (widget.initialData!.year != null) {
        if (!_availableYears.contains(widget.initialData!.year)) {
          // Add the year to the list if it's not already included
          _availableYears.add(widget.initialData!.year!);
          // Sort the list to keep it in order
          _availableYears.sort();
        }
        _selectedYear = widget.initialData!.year!;
      } else {
        _selectedYear = currentYear;
      }
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

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      // Show selected image from bytes
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Change Image', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_initialImageUrl != null && _keepExistingImage) {
      // Show existing image from URL
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _initialImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 36),
                    SizedBox(height: 8),
                    Text('Error loading image'),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Change Image', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Show placeholder
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 64, color: Colors.blue[300]),
              const SizedBox(height: 12),
              const Text(
                'Click to upload membership card design',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recommended size: 1024×576 pixels',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
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
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40.0),
                      child: Text(
                        widget.isEdit ? 'Edit Membership Campaign' : 'Start New Campaign',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Form content in scrollable area
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Campaign name
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Campaign Name',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a campaign name';
                                }
                                if (value.length > 100) {
                                  return 'Name cannot exceed 100 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Year, Start Date and End Date in one row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Year dropdown
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<int>(
                                    decoration: const InputDecoration(
                                      labelText: 'Year',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                                        
                                        // Automatically update start date year if needed
                                        if (_startDate.year != value &&
                                            _startDate.year != value - 1 &&
                                            _startDate.year != value + 1) {
                                          // Adjust start date to be in the selected year
                                          _startDate = DateTime(value, _startDate.month, _startDate.day);
                                          
                                          // If end date exists, check if it's still valid
                                          if (_endDate != null && _endDate!.isBefore(_startDate)) {
                                            _endDate = null;
                                          }
                                        }
                                      });
                                      _formKey.currentState?.validate(); // Re-validate form
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Required';
                                      }
                                      
                                      // Now we're automatically syncing the date and year, so no additional validation needed
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Start Date
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
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
                                          // Update campaign year to match start date year
                                          _selectedYear = pickedDate.year;
                                          // If end date exists and is now before start date, clear it
                                          if (_endDate != null && _endDate!.isBefore(_startDate)) {
                                            _endDate = null;
                                          }
                                          
                                          // Ensure year is in the available years list
                                          if (!_availableYears.contains(_selectedYear)) {
                                            _availableYears.add(_selectedYear);
                                            _availableYears.sort();
                                          }
                                        });
                                        _formKey.currentState?.validate(); // Re-validate form
                                      }
                                    },
                                    child: FormField<DateTime>(
                                      initialValue: _startDate,
                                      validator: (value) {
                                        // Add validation if needed for start date
                                        if (value == null) {
                                          return 'Start date is required';
                                        }
                                        
                                        // Check if start date is in the past (more than 1 year)
                                        if (value.isBefore(DateTime.now().subtract(const Duration(days: 365)))) {
                                          return 'Start date cannot be more than 1 year in the past';
                                        }
                                        
                                        return null;
                                      },
                                      builder: (FormFieldState<DateTime> field) {
                                        return InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'Start Date',
                                            border: const OutlineInputBorder(),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            errorText: field.errorText,
                                            suffixIcon: const Padding(
                                              padding: EdgeInsets.only(right: 8.0),
                                              child: Icon(Icons.calendar_today),
                                            ),
                                          ),
                                          child: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // End Date (Optional)
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                                        firstDate: _startDate.add(const Duration(days: 1)), // Must be after start date
                                        lastDate: DateTime(_selectedYear + 3, 12, 31), // Limit to 3 years after campaign year
                                      );
                                      if (pickedDate != null) {
                                        setState(() {
                                          _endDate = pickedDate;
                                        });
                                        _formKey.currentState?.validate(); // Re-validate form to check end date
                                      }
                                    },
                                    child: FormField<DateTime?>(
                                      initialValue: _endDate,
                                      validator: (value) {
                                        // End date is optional, but if specified must be after start date
                                        if (value != null) {
                                          if (value.isBefore(_startDate) || value.isAtSameMomentAs(_startDate)) {
                                            return 'End date must be after start date';
                                          }
                                          
                                          // End date shouldn't be too far in the future (e.g., more than 5 years)
                                          if (value.isAfter(_startDate.add(const Duration(days: 365 * 5)))) {
                                            return 'End date too far in the future';
                                          }
                                          
                                          // End date year should be related to campaign year
                                          if (value.year > _selectedYear + 3) {
                                            return 'End date too far from campaign year';
                                          }
                                        }
                                        return null;
                                      },
                                      builder: (FormFieldState<DateTime?> field) {
                                        return InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'End Date (Optional)',
                                            border: const OutlineInputBorder(),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            errorText: field.errorText,
                                            suffixIcon: _endDate != null
                                              ? Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.clear, size: 20),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        setState(() {
                                                          _endDate = null;
                                                          field.didChange(null);
                                                        });
                                                      },
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Padding(
                                                      padding: EdgeInsets.only(right: 8.0),
                                                      child: Icon(Icons.calendar_today),
                                                    ),
                                                  ],
                                                )
                                              : const Padding(
                                                  padding: EdgeInsets.only(right: 8.0),
                                                  child: Icon(Icons.calendar_today),
                                                ),
                                          ),
                                          child: Text(_endDate != null
                                              ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                              : 'Not specified'),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Target goal and price in one row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Target goal
                                Expanded(
                                  child: TextFormField(
                                    controller: _targetGoalController,
                                    decoration: const InputDecoration(
                                      labelText: 'Target Goal',
                                      border: OutlineInputBorder(),
                                      hintText: 'e.g., 9823',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      
                                      final target = int.tryParse(value);
                                      if (target == null) {
                                        return 'Enter a valid number';
                                      }
                                      
                                      if (target <= 0) {
                                        return 'Target must be greater than 0';
                                      }
                                      
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Price
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Price',
                                      border: OutlineInputBorder(),
                                      prefixText: '\$',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      
                                      final price = double.tryParse(value);
                                      if (price == null) {
                                        return 'Enter a valid number';
                                      }
                                      
                                      if (price <= 0) {
                                        return 'Price must be greater than 0';
                                      }
                                      
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a description for the campaign';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Benefits
                            TextFormField(
                              controller: _benefitsController,
                              decoration: const InputDecoration(
                                labelText: 'Benefits',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please list membership benefits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Image upload
                            FormField<bool>(
                              initialValue: _imageBytes != null || (_initialImageUrl != null && _keepExistingImage),
                              validator: (value) {
                                if (_imageBytes == null && (_initialImageUrl == null || !_keepExistingImage)) {
                                  return 'Please add a membership card design image';
                                }
                                return null;
                              },
                              builder: (FormFieldState<bool> field) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                                      child: Text(
                                        'Membership Card Design',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Material(
                                      elevation: 1,
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: () {
                                          _pickImage();
                                          field.didChange(true);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          height: 200,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: field.hasError ? Colors.red : Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(7),
                                            child: _buildImagePreview(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    if (field.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                                        child: Text(
                                          field.errorText!,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.error,
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ),
                                    
                                    if (widget.isEdit && _initialImageUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: _keepExistingImage,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _keepExistingImage = value!;
                                                    field.didChange(_imageBytes != null || (_initialImageUrl != null && _keepExistingImage));
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Keep existing image if no new one is selected'),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom buttons with divider
                  Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            icon: Icon(widget.isEdit ? Icons.check : Icons.add_card),
                            label: Text(widget.isEdit ? 'Update Campaign' : 'Start Campaign'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () async {
                              // Validate form (this will now include all our validations)
                              bool isValid = _formKey.currentState!.validate();
                              
                              if (isValid) {
                                // Create form object to use our model validation
                                final formData = MembershipCardForm(
                                  year: _selectedYear,
                                  name: _nameController.text,
                                  description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                                  targetMembers: int.tryParse(_targetGoalController.text),
                                  price: double.tryParse(_priceController.text),
                                  startDate: _startDate,
                                  endDate: _endDate,
                                  benefits: _benefitsController.text.isEmpty ? null : _benefitsController.text,
                                  isActive: true,
                                  keepImage: _keepExistingImage,
                                  image: _imageBytes ?? (_initialImageUrl != null && _keepExistingImage ? _initialImageUrl : null),
                                );
                                
                                // Validate using our model validation
                                final modelErrors = formData.validate();
                                if (modelErrors.isNotEmpty) {
                                  // Show errors
                                  String errorMessage = 'Please fix the following errors:\n';
                                  modelErrors.forEach((field, error) {
                                    if (error != null) {
                                      errorMessage += '• $error\n';
                                    }
                                  });
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                  return;
                                }

                                // Show in-dialog confirmation
                                final shouldContinue = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(widget.isEdit ? 'Update Campaign?' : 'Create New Campaign?'),
                                    content: Text(
                                      widget.isEdit 
                                        ? 'Are you sure you want to update this campaign?'
                                        : 'Are you sure you want to create this campaign?'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.of(dialogContext).pop(true),
                                        child: Text(widget.isEdit ? 'Update' : 'Create'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (shouldContinue == true) {
                                  final result = formData.toJson();
                                  
                                  // Add image data if available
                                  if (_imageBytes != null) {
                                    result['imageBytes'] = _imageBytes;
                                    result['fileName'] = _selectedImageName ?? _imageFile?.path.split('/').last ?? 'membership_card.jpg';
                                  }
                                  
                                  Navigator.of(context).pop(result);
                                }
                              }
                            },
                          ),
                        ],
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
}
