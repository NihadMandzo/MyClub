import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myclub_desktop/models/club.dart';
import 'package:myclub_desktop/providers/club_provider.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClubProvider(),
      child: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent({Key? key}) : super(key: key);

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  bool _isEditing = false;
  bool _isLoading = true;
  Club? _club;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedLogoFile;

  @override
  void initState() {
    super.initState();
    _loadClub();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClub() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<ClubProvider>(context, listen: false);
      provider.setContext(context);

      try {
        // Try to get the club by ID 1 (assuming there's only one club in the system)
        final club = await provider.getById(1);
        setState(() {
          _club = club;
          _nameController.text = club.name;
          _descriptionController.text = club.description;
        });
      } catch (e) {
        // If that fails, try to get all clubs and use the first one
        final result = await provider.get();
        if (result.data.isNotEmpty) {
          setState(() {
            _club = result.data.first;
            _nameController.text = _club!.name;
            _descriptionController.text = _club!.description;
          });
        }
      }
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom učitavanja informacija o klubu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectLogoImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedLogoFile = File(result.files.first.path!);
      });
    }
  }

  Future<void> _saveClub() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<ClubProvider>(context, listen: false);
      
      final updatedClub = await provider.updateClub(
        _club!.id,
        _nameController.text,
        _descriptionController.text,
        _selectedLogoFile,
      );
      
      if (updatedClub != null) {
        setState(() {
          _club = updatedClub;
          _isEditing = false;
          _selectedLogoFile = null;
        });

        NotificationUtility.showSuccess(context, message: 'Informacije o klubu su uspješno ažurirane');
      }
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom ažuriranja informacija o klubu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_club == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nema dostupnih informacija o klubu',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadClub,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    return _isEditing ? _buildEditForm() : _buildClubInfo();
  }

  Widget _buildClubInfo() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo on the left
                  if (_club!.imageUrl != null && _club!.imageUrl!.isNotEmpty)
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _club!.imageUrl!,
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error rendering image: $error');
                            return Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.broken_image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  
                  const SizedBox(width: 24),
                  
                  // Club name and description on the right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _club!.name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _club!.description,
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Additional content can go here
              const SizedBox(height: 32),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            tooltip: 'Uredi informacije o klubu',
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Uredi informacije o klubu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      image: _selectedLogoFile != null
                          ? DecorationImage(
                              image: FileImage(_selectedLogoFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedLogoFile == null
                        ? _club!.imageUrl != null && _club!.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _club!.imageUrl!,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / 
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error rendering image in edit form: $error');
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                        onPressed: _selectLogoImage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv kluba',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Molimo unesite naziv kluba';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Opis kluba',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Molimo unesite opis kluba';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _selectedLogoFile = null;
                        if (_club != null) {
                          _nameController.text = _club!.name;
                          _descriptionController.text = _club!.description;
                        }
                      });
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Otkaži'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveClub,
                    icon: const Icon(Icons.save),
                    label: const Text('Spremi promjene'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
