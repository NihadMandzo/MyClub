import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myclub_desktop/models/club.dart';
import 'package:myclub_desktop/models/country.dart';
import 'package:myclub_desktop/models/city.dart';
import 'package:myclub_desktop/models/stadium_side.dart';
import 'package:myclub_desktop/models/stadium_sector.dart';
import 'package:myclub_desktop/providers/club_provider.dart';
import 'package:myclub_desktop/providers/country_provider.dart';
import 'package:myclub_desktop/providers/city_provider.dart';
import 'package:myclub_desktop/providers/stadium_side_provider.dart';
import 'package:myclub_desktop/providers/stadium_sector_provider.dart';
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
  
  // Current selected menu item
  String _selectedMenuItem = 'Informacije o klubu';
  
  // Providers
  late CountryProvider _countryProvider;
  late CityProvider _cityProvider;
  late StadiumSideProvider _stadiumSideProvider;
  late StadiumSectorProvider _stadiumSectorProvider;
  
  // Data lists
  List<Country> _countries = [];
  List<City> _cities = [];
  List<StadiumSide> _stadiumSides = [];
  List<StadiumSector> _stadiumSectors = [];
  
  // Selected items for relationships
  Country? _selectedCountry;
  StadiumSide? _selectedStadiumSide;
  
  // Form controllers
  final TextEditingController _countryNameController = TextEditingController();
  final TextEditingController _cityNameController = TextEditingController();
  final TextEditingController _cityPostalCodeController = TextEditingController();
  final TextEditingController _stadiumSideNameController = TextEditingController();
  final TextEditingController _stadiumSectorCodeController = TextEditingController();
  final TextEditingController _stadiumSectorCapacityController = TextEditingController();
  
  // Editing states
  bool _isEditingCountry = false;
  bool _isEditingCity = false;
  bool _isEditingStadiumSide = false;
  bool _isEditingStadiumSector = false;
  
  // Currently editing item IDs
  int? _editingCountryId;
  int? _editingCityId;
  int? _editingStadiumSideId;
  int? _editingStadiumSectorId;

  @override
  void initState() {
    super.initState();
    
    // Initialize providers
    _countryProvider = CountryProvider();
    _cityProvider = CityProvider();
    _stadiumSideProvider = StadiumSideProvider();
    _stadiumSectorProvider = StadiumSectorProvider();
    
    _loadClub();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _countryNameController.dispose();
    _cityNameController.dispose();
    _cityPostalCodeController.dispose();
    _stadiumSideNameController.dispose();
    _stadiumSectorCodeController.dispose();
    _stadiumSectorCapacityController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _countryProvider.setContext(context);
      final result = await _countryProvider.get();
      setState(() {
        _countries = result.data;
      });
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom učitavanja država: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _cityProvider.setContext(context);
      final result = await _cityProvider.get();
      setState(() {
        _cities = result.data;
      });
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom učitavanja gradova: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStadiumSides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _stadiumSideProvider.setContext(context);
      final result = await _stadiumSideProvider.get();
      setState(() {
        _stadiumSides = result.data;
      });
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom učitavanja strana stadiona: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStadiumSectors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _stadiumSectorProvider.setContext(context);
      final result = await _stadiumSectorProvider.get();
      setState(() {
        _stadiumSectors = result.data;
      });
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom učitavanja sektora stadiona: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  

  
  Widget _buildCountryForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingCountryId == null ? 'Nova država' : 'Uredi državu',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryNameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv države',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Molimo unesite naziv države';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingCountry = false;
                          _editingCountryId = null;
                        });
                      },
                      child: const Text('Otkaži'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveCountry,
                      child: Text(_editingCountryId == null ? 'Dodaj' : 'Spremi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  
  Future<void> _saveCountry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _countryProvider.setContext(context);
      
      if (_editingCountryId == null) {
        // Create new country
        await _countryProvider.insert({
          'name': _countryNameController.text,
        });
        NotificationUtility.showSuccess(context, message: 'Država uspješno dodana');
      } else {
        // Update existing country
        await _countryProvider.update(_editingCountryId!, {
          'name': _countryNameController.text,
        });
        NotificationUtility.showSuccess(context, message: 'Država uspješno ažurirana');
      }
      
      setState(() {
        _isEditingCountry = false;
        _editingCountryId = null;
        _countryNameController.clear();
      });
      
      _loadCountries();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom spremanja države: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteCountry(int id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: const Text('Jeste li sigurni da želite obrisati ovu državu? Ova akcija se ne može poništiti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Obriši', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _countryProvider.setContext(context);
      await _countryProvider.delete(id);
      NotificationUtility.showSuccess(context, message: 'Država uspješno obrisana');
      _loadCountries();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom brisanja države: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  

  
  Widget _buildCityForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingCityId == null ? 'Novi grad' : 'Uredi grad',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityNameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv grada',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Molimo unesite naziv grada';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityPostalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Poštanski broj',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Molimo unesite poštanski broj';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Country>(
                  decoration: const InputDecoration(
                    labelText: 'Država',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCountry,
                  items: _countries.map((country) {
                    return DropdownMenuItem<Country>(
                      value: country,
                      child: Text(country.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Molimo odaberite državu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingCity = false;
                          _editingCityId = null;
                        });
                      },
                      child: const Text('Otkaži'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveCity,
                      child: Text(_editingCityId == null ? 'Dodaj' : 'Spremi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  
  Future<void> _saveCity() async {
    if (!_formKey.currentState!.validate() || _selectedCountry == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _cityProvider.setContext(context);
      
      if (_editingCityId == null) {
        // Create new city
        await _cityProvider.insert({
          'name': _cityNameController.text,
          'postalCode': _cityPostalCodeController.text,
          'countryId': _selectedCountry!.id,
        });
        NotificationUtility.showSuccess(context, message: 'Grad uspješno dodan');
      } else {
        // Update existing city
        await _cityProvider.update(_editingCityId!, {
          'name': _cityNameController.text,
          'postalCode': _cityPostalCodeController.text,
          'countryId': _selectedCountry!.id,
        });
        NotificationUtility.showSuccess(context, message: 'Grad uspješno ažuriran');
      }
      
      setState(() {
        _isEditingCity = false;
        _editingCityId = null;
        _cityNameController.clear();
        _cityPostalCodeController.clear();
      });
      
      _loadCities();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom spremanja grada: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteCity(int id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: const Text('Jeste li sigurni da želite obrisati ovaj grad? Ova akcija se ne može poništiti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Obriši', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _cityProvider.setContext(context);
      await _cityProvider.delete(id);
      NotificationUtility.showSuccess(context, message: 'Grad uspješno obrisan');
      _loadCities();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom brisanja grada: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  

  
  Widget _buildStadiumSideForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingStadiumSideId == null ? 'Nova strana stadiona' : 'Uredi stranu stadiona',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stadiumSideNameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv strane stadiona',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Molimo unesite naziv strane stadiona';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingStadiumSide = false;
                          _editingStadiumSideId = null;
                        });
                      },
                      child: const Text('Otkaži'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveStadiumSide,
                      child: Text(_editingStadiumSideId == null ? 'Dodaj' : 'Spremi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  
  Future<void> _saveStadiumSide() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _stadiumSideProvider.setContext(context);
      
      if (_editingStadiumSideId == null) {
        // Create new stadium side
        await _stadiumSideProvider.insert({
          'name': _stadiumSideNameController.text,
        });
        NotificationUtility.showSuccess(context, message: 'Strana stadiona uspješno dodana');
      } else {
        // Update existing stadium side
        await _stadiumSideProvider.update(_editingStadiumSideId!, {
          'name': _stadiumSideNameController.text,
        });
        NotificationUtility.showSuccess(context, message: 'Strana stadiona uspješno ažurirana');
      }
      
      setState(() {
        _isEditingStadiumSide = false;
        _editingStadiumSideId = null;
        _stadiumSideNameController.clear();
      });
      
      _loadStadiumSides();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom spremanja strane stadiona: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteStadiumSide(int id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: const Text('Jeste li sigurni da želite obrisati ovu stranu stadiona? Ova akcija se ne može poništiti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Obriši', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _stadiumSideProvider.setContext(context);
      await _stadiumSideProvider.delete(id);
      NotificationUtility.showSuccess(context, message: 'Strana stadiona uspješno obrisana');
      _loadStadiumSides();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom brisanja strane stadiona: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  

  
  // Get filtered sectors for the selected stadium side
  List<StadiumSector> get _filteredStadiumSectors {
    if (_selectedStadiumSide == null) return [];
    return _stadiumSectors.where((sector) => 
        sector.sideName == _selectedStadiumSide!.name).toList();
  }
  
  // Stadium side selector when no side is selected
  Widget _buildStadiumSideSelector() {
    return _stadiumSides.isEmpty
        ? _buildEmptyState(
            'Prvo dodajte strane stadiona',
            'Idi na strane stadiona',
            () {
              setState(() {
                _selectedMenuItem = 'Strane stadiona';
              });
            })
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stadiumSides.length,
            itemBuilder: (context, index) {
              final side = _stadiumSides[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.stadium),
                  title: Text(side.name),
                  onTap: () {
                    setState(() {
                      _selectedStadiumSide = side;
                    });
                  },
                ),
              );
            },
          );
  }
  
  Widget _buildStadiumSectorForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingStadiumSectorId == null ? 'Novi sektor' : 'Uredi sektor',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stadiumSectorCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Oznaka sektora',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Molimo unesite oznaku sektora';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stadiumSectorCapacityController,
                  decoration: const InputDecoration(
                    labelText: 'Kapacitet',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Molimo unesite kapacitet sektora';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Kapacitet mora biti pozitivan broj';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingStadiumSector = false;
                          _editingStadiumSectorId = null;
                        });
                      },
                      child: const Text('Otkaži'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveStadiumSector,
                      child: Text(_editingStadiumSectorId == null ? 'Dodaj' : 'Spremi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStadiumSectorsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredStadiumSectors.length,
      itemBuilder: (context, index) {
        final sector = _filteredStadiumSectors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('Sektor ${sector.code}'),
            subtitle: Text('Kapacitet: ${sector.capacity}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      _isEditingStadiumSector = true;
                      _editingStadiumSectorId = sector.id;
                      _stadiumSectorCodeController.text = sector.code;
                      _stadiumSectorCapacityController.text = sector.capacity.toString();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStadiumSector(sector.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _saveStadiumSector() async {
    if (!_formKey.currentState!.validate() || _selectedStadiumSide == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _stadiumSectorProvider.setContext(context);
      
      if (_editingStadiumSectorId == null) {
        // Create new stadium sector
        await _stadiumSectorProvider.insert({
          'code': _stadiumSectorCodeController.text,
          'capacity': int.parse(_stadiumSectorCapacityController.text),
          'stadiumSideId': _selectedStadiumSide!.id,
        });
        NotificationUtility.showSuccess(context, message: 'Sektor stadiona uspješno dodan');
      } else {
        // Update existing stadium sector
        await _stadiumSectorProvider.update(_editingStadiumSectorId!, {
          'code': _stadiumSectorCodeController.text,
          'capacity': int.parse(_stadiumSectorCapacityController.text),
          'stadiumSideId': _selectedStadiumSide!.id,
        });
        NotificationUtility.showSuccess(context, message: 'Sektor stadiona uspješno ažuriran');
      }
      
      setState(() {
        _isEditingStadiumSector = false;
        _editingStadiumSectorId = null;
        _stadiumSectorCodeController.clear();
        _stadiumSectorCapacityController.clear();
      });
      
      _loadStadiumSectors();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom spremanja sektora stadiona: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteStadiumSector(int id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: const Text('Jeste li sigurni da želite obrisati ovaj sektor stadiona? Ova akcija se ne može poništiti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Obriši', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _stadiumSectorProvider.setContext(context);
      await _stadiumSectorProvider.delete(id);
      NotificationUtility.showSuccess(context, message: 'Sektor stadiona uspješno obrisan');
      _loadStadiumSectors();
    } catch (e) {
      NotificationUtility.showError(context, message: 'Greška prilikom brisanja sektora stadiona: $e');
      setState(() {
        _isLoading = false;
      });
    }
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

  // List of menu items for the sidebar
  final List<String> _menuItems = [
    'Informacije o klubu',
    'Lokacije',
    'Stadion',
  ];

  // Method to build the sidebar
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          final isSelected = _selectedMenuItem == item;
          
          return ListTile(
            title: Text(
              item,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
            leading: Icon(
              _getIconForMenuItem(item),
              color: isSelected ? Theme.of(context).primaryColor : Colors.black54,
            ),
            selected: isSelected,
            selectedTileColor: Colors.blue.withOpacity(0.1),
            onTap: () {
              setState(() {
                _selectedMenuItem = item;
                // Reset editing mode when changing sections
                _isEditing = false;
              });
            },
          );
        },
      ),
    );
  }

  // Helper method to get appropriate icon for each menu item
  IconData _getIconForMenuItem(String item) {
    switch (item) {
      case 'Informacije o klubu':
        return Icons.sports_soccer;
      case 'Lokacije':
        return Icons.location_on;
      case 'Stadion':
        return Icons.stadium;
      default:
        return Icons.settings;
    }
  }

  // Method to display the content based on the selected menu item
  Widget _buildContent() {
    switch (_selectedMenuItem) {
      case 'Informacije o klubu':
        return _isEditing ? _buildEditForm() : _buildClubInfo();
      case 'Lokacije':
        return _buildLocationsScreen();
      case 'Stadion':
        return _buildStadiumScreen();
      default:
        return _buildClubInfo();
    }
  }
  
  // Locations screen with countries and cities in a hierarchical structure
  Widget _buildLocationsScreen() {
    if (_countries.isEmpty) {
      _loadCountries();
    }
    if (_cities.isEmpty) {
      _loadCities();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Navigation tree for countries and cities
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Lokacije',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _countries.isEmpty
                          ? Center(
                              child: Text('Nema dostupnih država',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            )
                          : _buildCountryTree(),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditingCountry = true;
                        _editingCountryId = null;
                        _countryNameController.clear();
                        // Reset selected country/city for editing
                        _selectedDetailItem = 'country';
                        _selectedCountryForDetail = null;
                        _selectedCityForDetail = null;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nova država'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Right side - Details panel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildLocationDetailPanel(),
            ),
          ),
        ],
      ),
    );
  }
  
  // Variables for detail panel
  String _selectedDetailItem = 'country'; // 'country' or 'city'
  Country? _selectedCountryForDetail;
  City? _selectedCityForDetail;
  
  // Build the country and city tree for navigation
  Widget _buildCountryTree() {
    return ListView.builder(
      itemCount: _countries.length,
      itemBuilder: (context, index) {
        final country = _countries[index];
        // Get cities for this country
        final countryCities = _cities
            .where((city) => city.country.id == country.id)
            .toList();
            
        // Check if this country is expanded
        final isExpanded = _selectedCountryForDetail?.id == country.id;
            
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country item
            InkWell(
              onTap: () {
                setState(() {
                  if (_selectedCountryForDetail?.id == country.id) {
                    // If already selected, just toggle expanded state
                    _selectedCountryForDetail = null;
                  } else {
                    // Select this country and show its details
                    _selectedCountryForDetail = country;
                    _selectedDetailItem = 'country';
                    _selectedCityForDetail = null;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: _selectedCountryForDetail?.id == country.id && _selectedDetailItem == 'country'
                      ? Colors.blue.withOpacity(0.2)
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                      color: Colors.grey.shade700,
                    ),
                    const Icon(Icons.flag, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        country.name,
                        style: TextStyle(
                          fontWeight: _selectedCountryForDetail?.id == country.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // City items if country is expanded
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var city in countryCities)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCityForDetail = city;
                            _selectedDetailItem = 'city';
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedCityForDetail?.id == city.id
                                ? Colors.blue.withOpacity(0.2)
                                : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_city, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  city.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedCityForDetail?.id == city.id
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Add city button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditingCity = true;
                            _editingCityId = null;
                            _cityNameController.clear();
                            _cityPostalCodeController.clear();
                            _selectedCountry = country;
                            _selectedDetailItem = 'city';
                            _selectedCountryForDetail = country;
                            _selectedCityForDetail = null;
                          });
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Dodaj grad', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 2),
          ],
        );
      },
    );
  }
  
  // Build the detail panel for country or city
  Widget _buildLocationDetailPanel() {
    if (_selectedDetailItem == 'country') {
      if (_isEditingCountry) {
        return _buildCountryForm();
      } else if (_selectedCountryForDetail != null) {
        // Show country details
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalji države',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _isEditingCountry = true;
                              _editingCountryId = _selectedCountryForDetail!.id;
                              _countryNameController.text = _selectedCountryForDetail!.name;
                            });
                          },
                          tooltip: 'Uredi državu',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCountry(_selectedCountryForDetail!.id),
                          tooltip: 'Obriši državu',
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailItem('Naziv države', _selectedCountryForDetail!.name),
                const SizedBox(height: 8),
                _buildDetailItem('Broj gradova', 
                  _cities.where((city) => city.country.id == _selectedCountryForDetail!.id).length.toString()),
              ],
            ),
          ),
        );
      } else {
        // No country selected
        return _buildEmptyDetailPanel('Odaberite državu iz navigacije');
      }
    } else if (_selectedDetailItem == 'city') {
      if (_isEditingCity) {
        return _buildCityForm();
      } else if (_selectedCityForDetail != null) {
        // Show city details
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalji grada',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _isEditingCity = true;
                              _editingCityId = _selectedCityForDetail!.id;
                              _cityNameController.text = _selectedCityForDetail!.name;
                              _cityPostalCodeController.text = _selectedCityForDetail!.postalCode;
                              _selectedCountry = _countries.firstWhere(
                                (country) => country.id == _selectedCityForDetail!.country.id,
                                orElse: () => _countries.first,
                              );
                            });
                          },
                          tooltip: 'Uredi grad',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCity(_selectedCityForDetail!.id),
                          tooltip: 'Obriši grad',
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailItem('Naziv grada', _selectedCityForDetail!.name),
                const SizedBox(height: 8),
                _buildDetailItem('Poštanski broj', _selectedCityForDetail!.postalCode),
                const SizedBox(height: 8),
                _buildDetailItem('Država', _selectedCityForDetail!.country.name),
              ],
            ),
          ),
        );
      } else {
        // No city selected, but we're in city mode (probably adding a new city)
        return _buildEmptyDetailPanel('Odaberite grad iz navigacije');
      }
    } else {
      return _buildEmptyDetailPanel('Odaberite državu ili grad iz navigacije');
    }
  }
  
  // Helper for building detail items
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  // Empty detail panel
  Widget _buildEmptyDetailPanel(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Stadium screen with sides and sectors in a hierarchical structure
  Widget _buildStadiumScreen() {
    if (_stadiumSides.isEmpty) {
      _loadStadiumSides();
    }
    if (_stadiumSectors.isEmpty) {
      _loadStadiumSectors();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Navigation tree for stadium sides and sectors
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Stadion',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _stadiumSides.isEmpty
                          ? Center(
                              child: Text('Nema dostupnih strana stadiona',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            )
                          : _buildStadiumTree(),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditingStadiumSide = true;
                        _editingStadiumSideId = null;
                        _stadiumSideNameController.clear();
                        // Reset selected side/sector for editing
                        _selectedDetailItem = 'stadiumSide';
                        _selectedStadiumSideForDetail = null;
                        _selectedStadiumSectorForDetail = null;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nova strana stadiona'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Right side - Details panel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildStadiumDetailPanel(),
            ),
          ),
        ],
      ),
    );
  }
  
  // Variables for stadium detail panel
  StadiumSide? _selectedStadiumSideForDetail;
  StadiumSector? _selectedStadiumSectorForDetail;
  
  // Build the stadium sides and sectors tree for navigation
  Widget _buildStadiumTree() {
    return ListView.builder(
      itemCount: _stadiumSides.length,
      itemBuilder: (context, index) {
        final side = _stadiumSides[index];
        // Get sectors for this side
        final sideSectors = _stadiumSectors
            .where((sector) => sector.sideName == side.name)
            .toList();
            
        // Check if this side is expanded
        final isExpanded = _selectedStadiumSideForDetail?.id == side.id;
            
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stadium side item
            InkWell(
              onTap: () {
                setState(() {
                  if (_selectedStadiumSideForDetail?.id == side.id) {
                    // If already selected, just toggle expanded state
                    _selectedStadiumSideForDetail = null;
                  } else {
                    // Select this side and show its details
                    _selectedStadiumSideForDetail = side;
                    _selectedDetailItem = 'stadiumSide';
                    _selectedStadiumSectorForDetail = null;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: _selectedStadiumSideForDetail?.id == side.id && _selectedDetailItem == 'stadiumSide'
                      ? Colors.blue.withOpacity(0.2)
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                      color: Colors.grey.shade700,
                    ),
                    const Icon(Icons.dashboard, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        side.name,
                        style: TextStyle(
                          fontWeight: _selectedStadiumSideForDetail?.id == side.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Sector items if side is expanded
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var sector in sideSectors)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedStadiumSectorForDetail = sector;
                            _selectedDetailItem = 'stadiumSector';
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedStadiumSectorForDetail?.id == sector.id
                                ? Colors.blue.withOpacity(0.2)
                                : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_seat, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sektor ${sector.code}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedStadiumSectorForDetail?.id == sector.id
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Add sector button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditingStadiumSector = true;
                            _editingStadiumSectorId = null;
                            _stadiumSectorCodeController.clear();
                            _stadiumSectorCapacityController.clear();
                            _selectedStadiumSide = side;
                            _selectedDetailItem = 'stadiumSector';
                            _selectedStadiumSideForDetail = side;
                            _selectedStadiumSectorForDetail = null;
                          });
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Dodaj sektor', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 2),
          ],
        );
      },
    );
  }
  
  // Build the stadium detail panel
  Widget _buildStadiumDetailPanel() {
    if (_selectedDetailItem == 'stadiumSide') {
      if (_isEditingStadiumSide) {
        return _buildStadiumSideForm();
      } else if (_selectedStadiumSideForDetail != null) {
        // Show stadium side details
        final sideSectors = _stadiumSectors
            .where((sector) => sector.sideName == _selectedStadiumSideForDetail!.name)
            .toList();
            
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalji strane stadiona',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _isEditingStadiumSide = true;
                              _editingStadiumSideId = _selectedStadiumSideForDetail!.id;
                              _stadiumSideNameController.text = _selectedStadiumSideForDetail!.name;
                            });
                          },
                          tooltip: 'Uredi stranu stadiona',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteStadiumSide(_selectedStadiumSideForDetail!.id),
                          tooltip: 'Obriši stranu stadiona',
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailItem('Naziv strane', _selectedStadiumSideForDetail!.name),
                const SizedBox(height: 8),
                _buildDetailItem('Broj sektora', sideSectors.length.toString()),
                if (sideSectors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Ukupni kapacitet: ${sideSectors.fold(0, (sum, sector) => sum + sector.capacity)} mjesta',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      } else {
        // No stadium side selected
        return _buildEmptyDetailPanel('Odaberite stranu stadiona iz navigacije');
      }
    } else if (_selectedDetailItem == 'stadiumSector') {
      if (_isEditingStadiumSector) {
        return _buildStadiumSectorForm();
      } else if (_selectedStadiumSectorForDetail != null) {
        // Show stadium sector details
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalji sektora stadiona',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _isEditingStadiumSector = true;
                              _editingStadiumSectorId = _selectedStadiumSectorForDetail!.id;
                              _stadiumSectorCodeController.text = _selectedStadiumSectorForDetail!.code;
                              _stadiumSectorCapacityController.text = _selectedStadiumSectorForDetail!.capacity.toString();
                              _selectedStadiumSide = _stadiumSides.firstWhere(
                                (side) => side.name == _selectedStadiumSectorForDetail!.sideName,
                                orElse: () => _stadiumSides.first,
                              );
                            });
                          },
                          tooltip: 'Uredi sektor',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteStadiumSector(_selectedStadiumSectorForDetail!.id),
                          tooltip: 'Obriši sektor',
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailItem('Oznaka sektora', _selectedStadiumSectorForDetail!.code),
                const SizedBox(height: 8),
                _buildDetailItem('Kapacitet', _selectedStadiumSectorForDetail!.capacity.toString()),
                const SizedBox(height: 8),
                _buildDetailItem('Strana stadiona', _selectedStadiumSectorForDetail!.sideName ?? 'Nepoznato'),
              ],
            ),
          ),
        );
      } else {
        // No stadium sector selected
        return _buildEmptyDetailPanel('Odaberite sektor stadiona iz navigacije');
      }
    } else {
      return _buildEmptyDetailPanel('Odaberite stranu ili sektor stadiona iz navigacije');
    }
  }

  // Placeholder widget for sections not yet implemented
  // Common empty state widget
  Widget _buildEmptyState(String message, String buttonText, VoidCallback? onPressed) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForMenuItem(_selectedMenuItem),
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          if (onPressed != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ],
      ),
    );
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

    // Return a row with sidebar on the left and content on the right
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildClubInfo() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
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
