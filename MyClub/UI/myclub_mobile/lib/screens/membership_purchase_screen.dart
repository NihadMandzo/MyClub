import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myclub_mobile/models/responses/paged_result.dart';
import 'package:myclub_mobile/models/search_objects/base_search_object.dart';
import 'package:myclub_mobile/providers/user_membership_card_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../models/responses/membership_card.dart';
import '../models/responses/city_response.dart';
import '../models/responses/payment_response.dart';
import '../models/requests/membership_purchase_request.dart';
import '../models/requests/shipping_request.dart';
import '../providers/membership_provider.dart';
import '../providers/city_provider.dart';
import '../providers/auth_provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../widgets/top_navbar.dart';

// Custom input formatters for card fields (reused from checkout_screen)
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    var newText = '';
    
    for (int i = 0; i < text.length; i++) {
      if (i % 4 == 0 && i != 0) {
        newText += ' ';
      }
      newText += text[i];
    }
    
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    var newText = '';
    
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        newText += '/';
      }
      newText += text[i];
    }
    
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// Screen for purchasing membership cards
class MembershipPurchaseScreen extends StatefulWidget {
  final MembershipCard membershipCard;

  const MembershipPurchaseScreen({
    super.key,
    required this.membershipCard,
  });

  @override
  State<MembershipPurchaseScreen> createState() => _MembershipPurchaseScreenState();
}

class _MembershipPurchaseScreenState extends State<MembershipPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserMembershipCardProvider _userMembershipCardProvider;
  late CityProvider _cityProvider;
  late AuthProvider _authProvider;

  // Form controllers
  final _recipientFirstNameController = TextEditingController();
  final _recipientLastNameController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  // Card form controllers
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvcController = TextEditingController();
  final _cardHolderNameController = TextEditingController();

  // Form data
  PagedResult<CityResponse> _cities = PagedResult<CityResponse>();
  int? _selectedCityId;
  String _selectedPaymentMethod = 'Stripe';
  bool _isGiftPurchase = false;
  bool _physicalCardRequested = false;
  bool _isLoading = false;
  bool _isLoadingCities = false;
  bool _isProcessingPayment = false;
  
  // Payment data
  PaymentResponse? _paymentResponse;
  String? _stripePaymentMethodId;

  @override
  void initState() {
    super.initState();
    _userMembershipCardProvider = context.read<UserMembershipCardProvider>();
    _cityProvider = context.read<CityProvider>();
    _authProvider = context.read<AuthProvider>();
    _userMembershipCardProvider.setContext(context);
    _cityProvider.setContext(context);
    _loadCities();
  }

  @override
  void dispose() {
    _recipientFirstNameController.dispose();
    _recipientLastNameController.dispose();
    _shippingAddressController.dispose();
    _postalCodeController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
    });

    BaseSearchObject searchObject = BaseSearchObject(retrieveAll: true);

    try {
      final cities = await _cityProvider.get(searchObject: searchObject);
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      print('Error loading cities: $e');
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri učitavanju gradova: $e');
      }
    } finally {
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _processPurchase() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate shipping if physical card is requested
    if (_physicalCardRequested && _selectedCityId == null) {
      NotificationHelper.showError(context, 'Molimo odaberite grad za dostavu fizičke kartice');
      return;
    }

    // For Stripe payments, we need the payment method first
    if (_selectedPaymentMethod == 'Stripe') {
      if (!_validateCardInputs()) {
        NotificationHelper.showError(context, 'Molimo unesite sve podatke kartice');
        return;
      }

      // Create Stripe payment method first
      await _createStripePaymentMethod();
      if (_stripePaymentMethodId == null) {
        return; // Error already shown
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final userId = _authProvider.userId;
      if (userId == null) {
        throw Exception('Korisnik nije autentificiran');
      }

      // Create shipping request if needed
      ShippingRequest? shippingRequest;
      if (_physicalCardRequested) {
        shippingRequest = ShippingRequest(
          shippingAddress: _shippingAddressController.text,
          cityId: _selectedCityId!,
          shippingPostalCode: _postalCodeController.text,
        );
      }

      // Determine payment method value
      String? paymentMethodValue;
      if (_selectedPaymentMethod == 'Stripe' && _stripePaymentMethodId != null) {
        paymentMethodValue = _stripePaymentMethodId; // Use Stripe payment method ID
      } else {
        paymentMethodValue = _selectedPaymentMethod; // Use "PayPal" for PayPal
      }

      // Create membership purchase request
      final purchaseRequest = MembershipPurchaseRequest(
        membershipCardId: widget.membershipCard.id ?? 0,
        type: _selectedPaymentMethod, // This tells backend if it's Stripe or PayPal
        amount: widget.membershipCard.price,
        paymentMethod: paymentMethodValue, // This contains the actual payment method ID from Stripe
        recipientFirstName: _isGiftPurchase ? _recipientFirstNameController.text.trim() : null,
        recipientLastName: _isGiftPurchase ? _recipientLastNameController.text.trim() : null,
        physicalCardRequested: _physicalCardRequested,
        shipping: shippingRequest,
      );

      // Purchase membership and get payment response
      print('Purchasing membership with request: ${purchaseRequest.toJson()}');
      final paymentResponse = await _userMembershipCardProvider.purchaseMembership(purchaseRequest);
      print('Membership purchase initiated, payment response received: ${paymentResponse.toJson()}');

      setState(() {
        _paymentResponse = paymentResponse;
      });

      if (mounted) {
        if (_selectedPaymentMethod == 'Stripe') {
          // Now process the Stripe payment
          await _processStripePayment();
        } else {
          NotificationHelper.showSuccess(context, 'Članstvo je rezervisano uspješno!');
        }
      }
    } catch (e) {
      print('Error in _processPurchase: $e');
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri kupovini članstva: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateCardInputs() {
    return _cardNumberController.text.isNotEmpty &&
           _cardExpiryController.text.isNotEmpty &&
           _cardCvcController.text.isNotEmpty &&
           _cardHolderNameController.text.isNotEmpty;
  }

  Future<void> _createStripePaymentMethod() async {
    try {
      // Parse expiry date (MM/YY format)
      final expiryParts = _cardExpiryController.text.split('/');
      if (expiryParts.length != 2) {
        throw Exception('Format datuma isteka mora biti MM/YY');
      }
      
      final expMonth = int.tryParse(expiryParts[0].trim());
      final expYear = int.tryParse('20${expiryParts[1].trim()}');
      
      if (expMonth == null || expYear == null || expMonth < 1 || expMonth > 12) {
        throw Exception('Nepravilan datum isteka kartice');
      }

      // For now, we'll create a simple payment method without the native card input
      // This is a workaround until the native Stripe components are properly configured
      print('Creating mock payment method for testing...');
      
      // Create a mock payment method ID that we can send to the backend
      // The backend will handle the actual Stripe processing
      _stripePaymentMethodId = 'pm_test_membership_${widget.membershipCard.id}'; // Unique test ID for membership

      print('Mock payment method created: $_stripePaymentMethodId');
    } catch (e) {
      print('Error creating payment method: $e');
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri kreiranju načina plaćanja: $e');
      }
    }
  }

  Future<void> _processStripePayment() async {
    if (_paymentResponse == null) {
      NotificationHelper.showError(context, 'Greška: Rezervacija nije kreirana');
      return;
    }

    if (_stripePaymentMethodId == null) {
      NotificationHelper.showError(context, 'Greška: Način plaćanja nije kreiran');
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // For the mock implementation, we'll simulate the payment confirmation
      print('Simulating Stripe payment confirmation for membership...');
      print('Payment Method ID: $_stripePaymentMethodId');
      print('Client Secret: ${_paymentResponse!.clientSecret}');

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Confirm membership purchase on backend
      print('Confirming membership purchase on backend...');
      await _userMembershipCardProvider.confirmMembershipPurchase(_paymentResponse!.transactionId);

      if (mounted) {
        NotificationHelper.showSuccess(context, 'Plaćanje uspješno! Članstvo je aktivirano.');
        // Navigate back to main screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Error processing Stripe payment: $e');
      if (mounted) {
        String errorMessage = 'Greška pri plaćanju: $e';
        
        // Handle specific Stripe errors
        if (e is stripe.StripeException) {
          final errorMessage = e.error.localizedMessage ?? e.error.message;
          NotificationHelper.showError(context, 'Greška pri plaćanju: $errorMessage');
        } else {
          NotificationHelper.showError(context, errorMessage);
        }
      }
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  double get totalAmount => widget.membershipCard.price;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(
        showCart: false,
        showBackButton: true,
      ),
      body: _isLoadingCities
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: ResponsiveHelper.pagePadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMembershipInfo(),
                    const SizedBox(height: 24),
                    _buildPurchaseOptions(),
                    const SizedBox(height: 24),
                    if (_isGiftPurchase) ...[
                      _buildGiftSection(),
                      const SizedBox(height: 24),
                    ],
                    if (_physicalCardRequested) ...[
                      _buildShippingSection(),
                      const SizedBox(height: 24),
                    ],
                    _buildPaymentSection(),
                    const SizedBox(height: 32),
                    _buildPurchaseButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMembershipInfo() {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_membership,
                  color: Theme.of(context).primaryColor,
                  size: ResponsiveHelper.iconSize(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Članstvo',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Membership name
            Text(
              widget.membershipCard.name,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            if (widget.membershipCard.description != null && widget.membershipCard.description!.isNotEmpty) ...[
              Text(
                widget.membershipCard.description!,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 14),
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Benefits
            if (widget.membershipCard.benefits != null && widget.membershipCard.benefits!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Benefiti:',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.membershipCard.benefits!,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 14),
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Price
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cijena:',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.membershipCard.price.toStringAsFixed(2)} KM',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 18),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOptions() {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opcije kupovine',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Gift purchase option
            CheckboxListTile(
              title: const Text('Kupi kao poklon'),
              subtitle: const Text('Članstvo za drugu osobu'),
              value: _isGiftPurchase,
              onChanged: (value) {
                setState(() {
                  _isGiftPurchase = value ?? false;
                });
              },
            ),
            
            // Physical card option
            CheckboxListTile(
              title: const Text('Fizička kartica'),
              subtitle: const Text('Pošaljite mi fizičku člansku karticu'),
              value: _physicalCardRequested,
              onChanged: (value) {
                setState(() {
                  _physicalCardRequested = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftSection() {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informacije o primaocu',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Recipient first name
            TextFormField(
              controller: _recipientFirstNameController,
              decoration: const InputDecoration(
                labelText: 'Ime primaoca *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (_isGiftPurchase && (value == null || value.trim().isEmpty)) {
                  return 'Ime primaoca je obavezno';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Recipient last name
            TextFormField(
              controller: _recipientLastNameController,
              decoration: const InputDecoration(
                labelText: 'Prezime primaoca *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (_isGiftPurchase && (value == null || value.trim().isEmpty)) {
                  return 'Prezime primaoca je obavezno';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingSection() {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adresa dostave',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Shipping address
            TextFormField(
              controller: _shippingAddressController,
              decoration: const InputDecoration(
                labelText: 'Adresa dostave *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (_physicalCardRequested && (value == null || value.trim().isEmpty)) {
                  return 'Adresa dostave je obavezna';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // City dropdown
            DropdownButtonFormField<int>(
              value: _selectedCityId,
              decoration: const InputDecoration(
                labelText: 'Grad *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _cities.result?.map((city) {
                return DropdownMenuItem<int>(
                  value: city.id,
                  child: Text(city.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCityId = value;
                });
              },
              validator: (value) {
                if (_physicalCardRequested && value == null) {
                  return 'Molimo odaberite grad';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Postal code
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Poštanski broj',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.markunread_mailbox),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Način plaćanja',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stripe expandable option
            ExpansionTile(
              title: Row(
                children: [
                  const Icon(Icons.credit_card, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Stripe (Kreditna/Debitna kartica)'),
                ],
              ),
              subtitle: _selectedPaymentMethod == 'Stripe' 
                  ? const Text('Odabrano', style: TextStyle(color: Colors.green))
                  : null,
              leading: Radio<String>(
                value: 'Stripe',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
              onExpansionChanged: (expanded) {
                if (expanded) {
                  setState(() {
                    _selectedPaymentMethod = 'Stripe';
                  });
                }
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Card number
                      TextFormField(
                        controller: _cardNumberController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                          CardNumberInputFormatter(),
                        ],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Broj kartice',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          // Expiry date
                          Expanded(
                            child: TextFormField(
                              controller: _cardExpiryController,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                ExpiryDateInputFormatter(),
                              ],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'MM/YY',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.date_range),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // CVC
                          Expanded(
                            child: TextFormField(
                              controller: _cardCvcController,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'CVC',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.security),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Cardholder name
                      TextFormField(
                        controller: _cardHolderNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ime vlasnika kartice',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // PayPal expandable option (disabled for now)
            ExpansionTile(
              title: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('PayPal'),
                ],
              ),
              leading: Radio<String>(
                value: 'PayPal',
                groupValue: _selectedPaymentMethod,
                onChanged: null, // Disabled for now
              ),
              onExpansionChanged: null, // Disabled for now
              children: const [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('PayPal opcija će biti dostupna uskoro.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || _isProcessingPayment) ? null : _processPurchase,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading || _isProcessingPayment
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isProcessingPayment ? 'Obrađujem plaćanje...' : 'Kupi članstvo...',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment),
                  const SizedBox(width: 8),
                  Text(
                    'Kupi članstvo - ${totalAmount.toStringAsFixed(2)} KM',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
