import 'package:flutter/material.dart';
import 'package:myclub_desktop/utilities/membership_card_dialog.dart';
import 'package:myclub_desktop/models/membership_card.dart';
import 'package:myclub_desktop/providers/membership_card_provider.dart';
import 'package:myclub_desktop/providers/auth_provider.dart';
import 'package:myclub_desktop/utilities/dialog_utility.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
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
      
      final result = await provider.get();
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
        _error = 'Failed to load membership campaigns: ${e.toString()}';
        _isLoading = false;
      });
      
      NotificationUtility.showError(
        context,
        message: 'Failed to load membership campaigns: ${e.toString()}',
      );
    }
  }

  Future<void> _createNewCampaign() async {
    final result = await MembershipCardDialog.show(
      context,
      initialData: MembershipCardForm(
        year: DateTime.now().year,
        startDate: DateTime.now(),
        isActive: true,
      ),
    );
    
    if (result != null) {
      setState(() {
        _isLoading = true;
      });
      
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
        
        // Refresh the campaign list
        await _loadCampaigns();
        
        NotificationUtility.showSuccess(
          context,
          message: 'Campaign created successfully',
        );
      } catch (e) {
        setState(() {
          _error = 'Failed to create campaign: ${e.toString()}';
          _isLoading = false;
        });
        
        NotificationUtility.showError(
          context,
          message: 'Failed to create campaign: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _editCampaign(MembershipCard campaign) async {
    final result = await MembershipCardDialog.show(
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
      
      if (!confirm) return;
      
      setState(() {
        _isLoading = true;
      });
      
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
        
        // Refresh the campaign list
        await _loadCampaigns();
        
        NotificationUtility.showSuccess(
          context,
          message: 'Campaign updated successfully',
        );
      } catch (e) {
        setState(() {
          _error = 'Failed to update campaign: ${e.toString()}';
          _isLoading = false;
        });
        
        NotificationUtility.showError(
          context,
          message: 'Failed to update campaign: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _toggleCampaignStatus(MembershipCard campaign) async {
    // Ask for confirmation before changing status
    final confirm = await DialogUtility.showConfirmation(
      context, 
      title: campaign.isActive ? 'Deactivate Campaign' : 'Activate Campaign',
      message: campaign.isActive 
        ? 'Are you sure you want to deactivate ${campaign.name}?' 
        : 'Are you sure you want to activate ${campaign.name}?',
    );
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final provider = Provider.of<MembershipCardProvider>(context, listen: false);
      final updateData = {
        'year': campaign.year,
        'name': campaign.name,
        'description': campaign.description,
        'targetMembers': campaign.targetMembers,
        'price': campaign.price,
        'startDate': campaign.startDate.toIso8601String(),
        'endDate': campaign.endDate?.toIso8601String(),
        'benefits': campaign.benefits,
        'isActive': !campaign.isActive,
        'keepPicture': true,
      };
      
      await provider.update(campaign.id, updateData);
      
      // Refresh the campaign list
      await _loadCampaigns();
      
      NotificationUtility.showSuccess(
        context,
        message: campaign.isActive 
          ? 'Campaign has been deactivated' 
          : 'Campaign has been activated',
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to update campaign status: ${e.toString()}';
        _isLoading = false;
      });
      
      NotificationUtility.showError(
        context,
        message: 'Failed to update campaign status: ${e.toString()}',
      );
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
                  child: const Text(
                    'Membership Campaigns',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                                onPressed: _loadCampaigns,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _campaigns.isEmpty 
                        ? const Center(
                            child: Text(
                              'No campaigns found.\nClick the button below to create one.',
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
                      label: const Text('Start New Campaign'),
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
                      'Select a campaign or create a new one',
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
                                    'Campaign for ${_selectedCampaign!.year}',
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
                                              _selectedCampaign!.isActive ? 'Active' : 'Inactive',
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
                                            'Target Goal:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text('${_selectedCampaign!.targetMembers} members'),
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
                                            'Current Members:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text('${_selectedCampaign!.totalMembers} members'),
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
                                            'Price:',
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
                                            'Start Date:',
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
                                              'End Date:',
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
                                              child: Text('Image not available'),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        height: 250,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Text('No image available'),
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
                                  'Campaign Progress',
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
                              '${_selectedCampaign!.totalMembers} of ${_selectedCampaign!.targetMembers} members',
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
                            'Description',
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
                            'Membership Benefits',
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
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Campaign'),
                              onPressed: () => _editCampaign(_selectedCampaign!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: Icon(_selectedCampaign!.isActive ? Icons.cancel : Icons.check_circle),
                              label: Text(_selectedCampaign!.isActive ? 'Deactivate' : 'Activate'),
                              onPressed: () => _toggleCampaignStatus(_selectedCampaign!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedCampaign!.isActive ? Colors.red : Colors.green,
                                foregroundColor: Colors.white,
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
