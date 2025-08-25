import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myclub_mobile/models/responses/paged_result.dart';
import 'package:myclub_mobile/models/search_objects/base_search_object.dart';
import 'package:myclub_mobile/providers/user_membership_card_provider.dart';
import 'package:myclub_mobile/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:url_launcher/url_launcher.dart';
import '../providers/paypal_provider.dart';
import '../models/responses/membership_card.dart';
import '../models/responses/city_response.dart';
import '../models/responses/payment_response.dart';
import '../models/requests/membership_purchase_request.dart';
import '../models/requests/shipping_request.dart';
import '../providers/city_provider.dart';
import '../providers/auth_provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../widgets/top_navbar.dart';
import '../widgets/payment_section_widget.dart';

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
  late PayPalProvider _paypalProvider;
  late UserProvider _userProvider;

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
  String _selectedPaymentMethod = '';
  bool _isGiftPurchase = false;
  bool _physicalCardRequested = false;
  bool _isLoading = false;
  bool _isLoadingCities = false;
  bool _isProcessingPayment = false;
  bool _isPayPalWaitingDialogOpen = false;
  bool _hasActiveMembership = false;
  
  // Payment data
  PaymentResponse? _paymentResponse;
  String? _stripePaymentMethodId;

  @override
  void initState() {
    super.initState();
    _userMembershipCardProvider = context.read<UserMembershipCardProvider>();
    _cityProvider = context.read<CityProvider>();
    _authProvider = context.read<AuthProvider>();
    _paypalProvider = context.read<PayPalProvider>();
    _userProvider = context.read<UserProvider>();
    
    _userMembershipCardProvider.setContext(context);
    _cityProvider.setContext(context);
    _paypalProvider.setContext(context);
    _loadCities();
    _checkActiveMembership();
  }
  
  Future<void> _checkActiveMembership() async {
    try {
      // Use the UserProvider method to check if user has active membership
      final hasMembership = await _userProvider.hasActiveUserMembership();
      
      setState(() {
        _hasActiveMembership = hasMembership;
        // If user has active membership, force gift purchase mode
        if (_hasActiveMembership) {
          _isGiftPurchase = true;
          // For gift purchases, physical card is mandatory
          _physicalCardRequested = true;
        }
      });
    } catch (e) {
      print('Error checking active membership: $e');
    }
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
  _paypalProvider.stopPaymentCheck(notify: false);
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
        NotificationHelper.showApiError(context, e, 'učitavanju gradova');
      }
    } finally {
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _processPurchase() async {
    print('=== MEMBERSHIP PURCHASE BUTTON PRESSED ===');
    print('Form validation: ${_formKey.currentState?.validate()}');
    print('Selected payment method: $_selectedPaymentMethod');
    print('Is gift purchase: $_isGiftPurchase');
    print('Physical card requested: $_physicalCardRequested');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    
    // Validate gift purchase with physical card requirement
    if (_isGiftPurchase && !_physicalCardRequested) {
      print('Gift purchase requires physical card');
      NotificationHelper.showError(context, 'Za poklon je fizička kartica obavezna');
      return;
    }
    
    // Validate shipping if physical card is requested
    if (_physicalCardRequested && _selectedCityId == null) {
      print('Physical card requested but no city selected');
      NotificationHelper.showError(context, 'Molimo odaberite grad za dostavu fizičke kartice');
      return;
    }

    // Ensure payment method selected
    if (_selectedPaymentMethod.isEmpty) {
      print('No payment method selected');
      NotificationHelper.showError(context, 'Molimo odaberite način plaćanja');
      return;
    }

    print('✅ Validation passed, proceeding with payment method: $_selectedPaymentMethod');    // For Stripe payments, we need the payment method first
    if (_selectedPaymentMethod == 'Stripe') {
      // Re-run validation to show inline field errors for card inputs
      final valid = _formKey.currentState!.validate();
      if (!valid) return;

      // Create Stripe payment method first
      await _createStripePaymentMethod();
      if (_stripePaymentMethodId == null) {
        return; // creation failed; error already surfaced
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

      if (!mounted) return;
      if (_selectedPaymentMethod == 'Stripe') {
        // Now process the Stripe payment
        await _processStripePayment();
      } else if (_selectedPaymentMethod == 'PayPal') {
        await _processPayPalPayment();
      } else {
        NotificationHelper.showSuccess(context, 'Članstvo je rezervisano uspješno!');
      }
    } catch (e) {
      print('Error in _processPurchase: $e');
      if (mounted) {
        NotificationHelper.showApiError(context, e, 'obradi rezervacije');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Card inputs are validated via Form validators in PaymentSectionWidget

  Future<void> _createStripePaymentMethod() async {
    try {
      final number = _cardNumberController.text.replaceAll(' ', '');
      final expiryParts = _cardExpiryController.text.split('/');
      final expMonth = int.parse(expiryParts[0].trim());
      final expYear = int.parse('20${expiryParts[1].trim()}');
      final cvc = _cardCvcController.text.trim();
      final holder = _cardHolderNameController.text.trim();

      await stripe.Stripe.instance.dangerouslyUpdateCardDetails(
        stripe.CardDetails(
          number: number,
          expirationMonth: expMonth,
          expirationYear: expYear,
          cvc: cvc,
        ),
      );

      final pm = await stripe.Stripe.instance.createPaymentMethod(
        params: stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(
            billingDetails: stripe.BillingDetails(
              name: holder.isNotEmpty ? holder : null,
            ),
          ),
        ),
      );
      _stripePaymentMethodId = pm.id;
      print('Stripe PaymentMethod created (ticket): $_stripePaymentMethodId');
    } on stripe.StripeException catch (e) {
      final msg = e.error.localizedMessage ?? e.error.message ?? 'Greška pri kreiranju načina plaćanja';
      if (mounted) NotificationHelper.showError(context, msg);
      _stripePaymentMethodId = null;
    } catch (e) {
      _stripePaymentMethodId = null;
    }
  }

  Future<void> _processStripePayment() async {
    if (_paymentResponse == null) {
      NotificationHelper.showError(context, 'Greška pri kreiranju rezervacije');
      return;
    }

    if (_stripePaymentMethodId == null) {
      NotificationHelper.showError(context, 'Greška pri kreiranju načina plaćanja');
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final clientSecret = _paymentResponse!.clientSecret;
      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Nedostaje Stripe client secret za potvrdu plaćanja');
      }

      final intent = await stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: stripe.PaymentMethodParams.cardFromMethodId(
          paymentMethodData: stripe.PaymentMethodDataCardFromMethod(
            paymentMethodId: _stripePaymentMethodId!,
          ),
        ),
      );

      print('Membership PaymentIntent status: ${intent.status}');
      if (intent.status == stripe.PaymentIntentsStatus.Succeeded) {
        // Confirm on backend only after success
        await _userMembershipCardProvider.confirmMembershipPurchase(_paymentResponse!.transactionId);
        if (mounted) {
          NotificationHelper.showSuccess(context, 'Plaćanje uspješno! Članstvo je aktivirano.');
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        throw Exception('Plaćanje nije uspjelo. Status: ${intent.status}');
      }
    } catch (e) {
      print('Error processing Stripe payment: $e');
      if (mounted) {
        // Handle specific Stripe errors
        if (e is stripe.StripeException) {
          NotificationHelper.showError(context, 'Greška pri plaćanju: ${e.error.localizedMessage ?? e.error.message ?? "Provjerite vaše podatke"}');
        } else {
          NotificationHelper.showApiError(context, e, 'Stripe plaćanju');
        }
      }
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _processPayPalPayment() async {
    if (_paymentResponse == null) {
      NotificationHelper.showError(context, 'Greška pri kreiranju rezervacije');
      return;
    }

    final approvalUrl = _paymentResponse!.approvalUrl;
    if (approvalUrl == null || approvalUrl.isEmpty) {
      NotificationHelper.showError(context, 'Greška pri kreiranju PayPal plaćanja');
      return;
    }

    try {
      final Uri paypalUri = Uri.parse(approvalUrl);
      final launched = await launchUrl(paypalUri, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Ne mogu otvoriti PayPal URL');

      // Start polling using the unified PayPalTest check endpoint
      _paypalProvider.startPaymentCheck(
        checkController: 'PayPalTest',
        orderIdForCheck: _paymentResponse!.transactionId,
        transactionIdForConfirm: _paymentResponse!.transactionId,
        confirmFn: (txId) async {
          await _userMembershipCardProvider.confirmMembershipPurchase(txId);
        },
        onComplete: (success, message) async {
          if (!mounted) return;
          if (_isPayPalWaitingDialogOpen && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            _isPayPalWaitingDialogOpen = false;
          }
          if (success) {
            await _showThankYouAndExit();
          } else {
            NotificationHelper.showError(context, message ?? 'Plaćanje nije uspjelo');
          }
        },
      );

      await _showPayPalWaitingDialog();
    } catch (e) {
      NotificationHelper.showApiError(context, e, 'PayPal plaćanju');
    }
  }

  Future<void> _showPayPalWaitingDialog() async {
    _isPayPalWaitingDialogOpen = true;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Consumer<PayPalProvider>(
            builder: (context, paypalProvider, child) {
              return AlertDialog(
                title: Row(
                  children: const [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Čekanje PayPal plaćanja', overflow: TextOverflow.ellipsis)),
                  ],
                ),
                content: const Text('Molimo završite plaćanje u PayPal-u'),
                actions: [
                  TextButton(
                    onPressed: () {
                      _paypalProvider.stopPaymentCheck();
                      Navigator.of(context).pop();
                      _isPayPalWaitingDialogOpen = false;
                    },
                    child: const Text('Prekini čekanje'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showThankYouAndExit() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: const [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Kupovina uspješna')]),
          content: const Text('Hvala! Članstvo je aktivirano.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Početna'),
            )
          ],
        );
      },
    );
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
              subtitle: Text(_hasActiveMembership 
                ? 'Već imate aktivno članstvo, možete kupiti samo kao poklon' 
                : 'Članstvo za drugu osobu'),
              value: _isGiftPurchase,
              onChanged: _hasActiveMembership 
                ? null // Disabled if user has active membership (it's forced to true)
                : (value) {
                    setState(() {
                      _isGiftPurchase = value ?? false;
                      // If gift purchase is selected, physical card is mandatory
                      if (_isGiftPurchase) {
                        _physicalCardRequested = true;
                      }
                    });
                  },
            ),
            
            // Physical card option
            CheckboxListTile(
              title: const Text('Fizička kartica'),
              subtitle: Text(_isGiftPurchase 
                ? 'Za poklon je fizička kartica obavezna' 
                : 'Pošaljite mi fizičku člansku karticu'),
              value: _physicalCardRequested,
              onChanged: _isGiftPurchase 
                ? null // Disabled if gift purchase (it's forced to true)
                : (value) {
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
    return PaymentSectionWidget(
      selectedPaymentMethod: _selectedPaymentMethod,
      onPaymentMethodChanged: (String method) {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      cardNumberController: _cardNumberController,
      cardExpiryController: _cardExpiryController,
      cardCvcController: _cardCvcController,
      cardHolderNameController: _cardHolderNameController,
      isProcessing: _isLoading || _isProcessingPayment,
    );
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || _isProcessingPayment) ? null : _processPurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isProcessingPayment ? 'Obrađujem plaćanje...' : 'Kupi članstvo...',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Kupi članstvo - ${totalAmount.toStringAsFixed(2)} KM',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
