import 'package:flutter/material.dart';
import 'package:myclub_desktop/providers/base_provider.dart';
import 'package:myclub_desktop/utilities/membership_card_dialog.dart';
import 'package:myclub_desktop/models/membership_card.dart';
import 'package:myclub_desktop/providers/membership_card_provider.dart';
import 'package:myclub_desktop/providers/auth_provider.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:myclub_desktop/models/search_objects/membership_search_object.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MembershipCardProvider(),
      child: const _MembershipContent(),
    );
  }
}

class _MembershipContent extends StatefulWidget {
  const _MembershipContent({Key? key}) : super(key: key);

  @override
  State<_MembershipContent> createState() => _MembershipContentState();
}

class _MembershipContentState extends State<_MembershipContent> {
  MembershipCard? _selectedCampaign;
  List<MembershipCard> _campaigns = [];
  bool _isLoading = true;
  String? _error;

  bool _includeInactive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<MembershipCardProvider>(context, listen: false);
    provider.setContext(context);
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<MembershipCardProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Ensure the provider has the authentication context
      provider.setContext(context);
      
      // Print debug info
      print("Loading membership campaigns...");
      print("Auth token available: ${authProvider.token != null}");
      
      // Create search object with filters
      final searchObject = MembershipSearchObject(
        fts: _searchController.text.isEmpty ? null : _searchController.text,
        includeInactive: _includeInactive,
      );

      print("Search object before: ${searchObject.toJson()}");
      print("includeInactive value: ${_includeInactive}");
      print("includeInactive in object: ${searchObject.includeInactive}");
      
      // Create the URL with query parameters to see what's actually being sent
      var filter = searchObject.toJson();
      print("Filter map: $filter");
      var queryString = Provider.of<MembershipCardProvider>(context, listen: false)
          .getQueryString(filter);
      var debugUrl = "${BaseProvider.baseUrl}${provider.endpoint}?$queryString";
      print("Debug URL: $debugUrl");

      final result = await provider.get(searchObject: searchObject);
      setState(() {
        _campaigns = result.data;
        _isLoading = false;
        
        // Select the first campaign by default if available
        if (_campaigns.isNotEmpty && _selectedCampaign == null) {
          _selectedCampaign = _campaigns.first;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Greška prilikom učitavanja kampanja članstva: ${e.toString()}';
        _isLoading = false;
      });
      
      NotificationUtility.showError(
        context,
        message: 'Greška prilikom učitavanja kampanja članstva: ${e.toString()}',
      );
    }
  }

  Future<void> _createNewCampaign() async {
    // Show dialog without setting loading state first
    final success = await MembershipCardDialog.createCampaign(context);
    
    if (success) {
      // Only set loading state after user has confirmed adding a campaign
      setState(() {
        _isLoading = true;
        _searchController.clear();
        _includeInactive = true; // Set to true to include inactive campaigns
      });
      
      // Add a small delay to ensure state is updated before loading
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Refresh the campaign list
      await _loadCampaigns();
    }
  }

  Future<void> _editCampaign(MembershipCard campaign) async {
    // Show dialog without setting loading state first
    final success = await MembershipCardDialog.editCampaign(context, campaign);
    
    if (success) {
      // Only set loading state after user has confirmed editing
      setState(() {
        _isLoading = true;
      });
      
      // Refresh the campaign list
      await _loadCampaigns();
    }
  }
  
  Future<void> _deleteCampaign(MembershipCard campaign) async {
    // Show confirmation dialog without setting loading state first
    final success = await MembershipCardDialog.deleteCampaign(context, campaign);
    
    if (success) {
      // Only set loading state after user has confirmed deletion
      setState(() {
        _isLoading = true;
        // Clear selection if deleted item was selected
        if (_selectedCampaign?.id == campaign.id) {
          _selectedCampaign = null;
        }
      });
      
      // Refresh the campaign list
      await _loadCampaigns();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left navigation drawer
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Drawer title
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.blue,
                  width: double.infinity,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Kampanje članstva',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            // Reset filters
                            _searchController.clear();
                            _includeInactive = false;
                          });
                          // Add a small delay to ensure the UI updates before loading
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _loadCampaigns();
                          });
                        },
                        tooltip: 'Osvježi',
                      ),
                    ],
                  ),
                ),
                
                // Search and filters
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Pretraži kampanje',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                        ),
                        onChanged: (value) {
                          // Debounce search
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (value == _searchController.text) {
                              _loadCampaigns();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Uključi neaktivne', style: TextStyle(fontSize: 14)),
                              value: _includeInactive,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onChanged: (bool? value) {
                                setState(() {
                                  _includeInactive = value ?? false;
                                  _loadCampaigns();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Campaign list
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    // Reset filters
                                    _searchController.clear();
                                    _includeInactive = false;
                                  });
                                  _loadCampaigns();
                                },
                                child: const Text('Ponovno pokušaj'),
                              ),
                            ],
                          ),
                        )
                      : _campaigns.isEmpty 
                        ? const Center(
                            child: Text(
                              'Nema pronađenih kampanja.\nKliknite dugme ispod da kreirate novu.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _campaigns.length,
                            itemBuilder: (context, index) {
                              final campaign = _campaigns[index];
                              final isSelected = _selectedCampaign?.id == campaign.id;
                              
                              return ListTile(
                                title: Text(campaign.name),
                                subtitle: Text('${campaign.year}'),
                                leading: CircleAvatar(
                                  backgroundColor: campaign.isActive ? Colors.green : Colors.grey,
                                  child: Icon(
                                    campaign.isActive ? Icons.check : Icons.cancel_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCampaign(campaign),
                                  tooltip: 'Obriši kampanju',
                                ),
                                selected: isSelected,
                                selectedTileColor: Colors.blue.withOpacity(0.1),
                                onTap: () {
                                  setState(() {
                                    _selectedCampaign = campaign;
                                  });
                                },
                              );
                            },
                          ),
                ),
                
                // Add new campaign button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Pokreni novu kampanju'),
                      onPressed: _createNewCampaign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: _selectedCampaign == null
                ? const Center(
                    child: Text(
                      'Odaberite kampanju ili kreirajte novu',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with basic info and image
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Campaign info
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedCampaign!.name,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  Text(
                                    'Kampanja za ${_selectedCampaign!.year}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Status
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            'Status:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Chip(
                                            label: Text(
                                              _selectedCampaign!.isActive ? 'Aktivna' : 'Neaktivna',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            backgroundColor: _selectedCampaign!.isActive ? Colors.green : Colors.grey,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Target Goal
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            'Cilj:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text('${_selectedCampaign!.targetMembers} članova'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Current Members
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            'Trenutni članovi:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text('${_selectedCampaign!.totalMembers} članova'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Price
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            'Cijena:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text('\$${_selectedCampaign!.price.toStringAsFixed(2)}'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Start Date
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            'Početak:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(DateFormat('MMMM d, yyyy').format(_selectedCampaign!.startDate)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // End Date (if available)
                                  if (_selectedCampaign!.endDate != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              'Kraj:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(DateFormat('MMMM d, yyyy').format(_selectedCampaign!.endDate!)),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // Image preview
                            Expanded(
                              flex: 2,
                              child: Card(
                                elevation: 4,
                                child: _selectedCampaign!.imageUrl != null
                                    ? Image.network(
                                        _selectedCampaign!.imageUrl!,
                                        height: 250,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 250,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Text('Slika nije dostupna'),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        height: 250,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Text('Slika nije dostupna'),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Napredak kampanje',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_selectedCampaign!.progressPercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _selectedCampaign!.progressPercentage / 100,
                              minHeight: 20,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _selectedCampaign!.progressPercentage >= 100 ? Colors.green : Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_selectedCampaign!.totalMembers} od ${_selectedCampaign!.targetMembers} članova',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Description section
                        if (_selectedCampaign!.description != null && _selectedCampaign!.description!.isNotEmpty) ...[
                          const Text(
                            'Opis',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _selectedCampaign!.description!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Benefits section
                        if (_selectedCampaign!.benefits != null && _selectedCampaign!.benefits!.isNotEmpty) ...[
                          const Text(
                            'Pogodnosti članstva',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _selectedCampaign!.benefits!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Izbriši', style: TextStyle(color: Colors.red)),
                              onPressed: () => _deleteCampaign(_selectedCampaign!),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Uredi kampanju'),
                              onPressed: () => _editCampaign(_selectedCampaign!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
