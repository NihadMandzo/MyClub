import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myclub_mobile/models/responses/paged_result.dart';
import 'package:myclub_mobile/models/search_objects/base_search_object.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../models/responses/cart_response.dart';
import '../models/responses/city_response.dart';
import '../models/responses/payment_response.dart';
import '../models/requests/order_insert_request.dart';
import '../models/requests/order_item_insert_request.dart';
import '../models/requests/shipping_request.dart';
import '../models/requests/confirm_order_request.dart';
import '../providers/order_provider.dart';
import '../providers/city_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/paypal_provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../widgets/top_navbar.dart';
import '../widgets/payment_section_widget.dart';

/// Checkout screen for order completion
class CheckoutScreen extends StatefulWidget {
  final CartResponse cart;

  const CheckoutScreen({
    super.key,
    required this.cart,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late OrderProvider _orderProvider;
  late CityProvider _cityProvider;
  late AuthProvider _authProvider;
  late PayPalProvider _paypalProvider;

  // Form controllers
  final _shippingAddressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Card form controllers
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvcController = TextEditingController();
  final _cardHolderNameController = TextEditingController();

  // Form data
  PagedResult<CityResponse> _cities = PagedResult<CityResponse>();
  int? _selectedCityId;
  String _selectedPaymentMethod = 'Stripe';
  bool _isLoading = false;
  bool _isLoadingCities = false;
  bool _isProcessingPayment = false;
  
  // Payment data
  PaymentResponse? _paymentResponse;
  String? _stripePaymentMethodId;
  Timer? _paypalResultTimer;
  bool _isPayPalWaitingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _orderProvider = context.read<OrderProvider>();
    _cityProvider = context.read<CityProvider>();
    _authProvider = context.read<AuthProvider>();
    _paypalProvider = context.read<PayPalProvider>();
    _orderProvider.setContext(context);
    _cityProvider.setContext(context);
    _paypalProvider.setContext(context);
    _loadCities();
  }

  @override
  void dispose() {
    _paypalResultTimer?.cancel();
  _paypalProvider.stopPaymentCheck(notify: false); // Stop PayPal checking when leaving screen
    _shippingAddressController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
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

    BaseSearchObject searchObject = new BaseSearchObject(retrieveAll: true);

    try {
      final cities = await _cityProvider.get(searchObject: searchObject);
      cities.result?.forEach((city) {
      });
      setState(() {
        _cities = cities;
      });
  } catch (e) {
      print('Error loading cities: $e');
      if (mounted) {
    NotificationHelper.showApiError(context, e);
      }
    } finally {
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _processCheckout() async {
    print('=== CHECKOUT BUTTON PRESSED ===');
    print('Selected payment method: $_selectedPaymentMethod');
    print('Form validation: ${_formKey.currentState?.validate()}');
    print('Selected city ID: $_selectedCityId');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed - check required fields');
      NotificationHelper.showError(context, 'Molimo popunite sva obavezna polja');
      return;
    }
    if (_selectedCityId == null) {
      print('No city selected');
      NotificationHelper.showError(context, 'Molimo odaberite grad za dostavu');
      return;
    }

    print('✅ Form validation passed - continuing with payment...');

    // For Stripe payments, we need the payment method first
    if (_selectedPaymentMethod == 'Stripe') {
      print('Validating Stripe card inputs...');
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
    
    // PayPal doesn't need card validation - it will redirect to PayPal
    print('Processing payment with method: $_selectedPaymentMethod');

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final userId = _authProvider.userId;
      if (userId == null) {
        throw Exception('Korisnik nije autentificiran');
      }

      // Create shipping request
      final shippingRequest = ShippingRequest(
        shippingAddress: _shippingAddressController.text,
        cityId: _selectedCityId!,
        shippingPostalCode: _postalCodeController.text,
      );

      // Convert cart items to order items
      final orderItems = widget.cart.items
          .map((item) => OrderItemInsertRequest(
                productSizeId: item.productSizeId,
                quantity: item.quantity,
                unitPrice: item.price,
              ))
          .toList();

      // Determine payment method value
      String? paymentMethodValue;
      if (_selectedPaymentMethod == 'Stripe' && _stripePaymentMethodId != null) {
        paymentMethodValue = _stripePaymentMethodId; // Use Stripe payment method ID
      } else if (_selectedPaymentMethod == 'PayPal') {
        paymentMethodValue = 'PayPal'; // For PayPal, just use the method name
      } else {
        paymentMethodValue = _selectedPaymentMethod;
      }

      // Create order request with PayPal URLs if needed
      final orderRequest = OrderInsertRequest(
        userId: userId,
        shipping: shippingRequest,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        items: orderItems,
        type: _selectedPaymentMethod, // This tells backend if it's Stripe or PayPal
        amount: widget.cart.finalAmount,
        paymentMethod: paymentMethodValue, // This contains the actual payment method ID from Stripe
        returnUrl: _selectedPaymentMethod == 'PayPal' ? 'myclub://payment/success' : null,
        cancelUrl: _selectedPaymentMethod == 'PayPal' ? 'myclub://payment/cancel' : null,
      );

      // Place order and get payment response
      print('Placing order with request: ${orderRequest.toJson()}');
      final paymentResponse = await _orderProvider.placeOrder(orderRequest);
      print('Order placed successfully, payment response received: ${paymentResponse.toJson()}');

      setState(() {
        _paymentResponse = paymentResponse;
      });

      if (mounted) {
        if (_selectedPaymentMethod == 'Stripe') {
          print('Processing Stripe payment...');
          // Process the Stripe payment
          await _processStripePayment();
        } else if (_selectedPaymentMethod == 'PayPal') {
          print('Processing PayPal payment...');
          // Process PayPal payment
          await _processPayPalPayment();
        } else {
          print('Unknown payment method: $_selectedPaymentMethod');
          NotificationHelper.showSuccess(context, 'Narudžba je kreirana uspješno!');
        }
      }
  } catch (e) {
      print('Error in _processCheckout: $e');
      if (mounted) {
    NotificationHelper.showApiError(context, e);
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
      _stripePaymentMethodId = 'pm_test_card_visa'; // Unique test ID

      print('Mock payment method created: $_stripePaymentMethodId');
  } catch (e) {
      print('Error creating payment method: $e');
      if (mounted) {
    NotificationHelper.showApiError(context, e);
      }
    }
  }

  Future<void> _processStripePayment() async {
    if (_paymentResponse == null) {
      NotificationHelper.showError(context, 'Greška: Narudžba nije kreirana');
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
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Confirm order on backend
      final confirmRequest = ConfirmOrderRequest(
        transactionId: _paymentResponse!.transactionId,
      );

      await _orderProvider.confirmOrder(confirmRequest);

      if (mounted) {
        await _showThankYouDialogAndExit();
      }
    } catch (e) {
      if (mounted) {
        if (e is stripe.StripeException) {
          final errorMessage = e.error.localizedMessage ?? e.error.message;
          NotificationHelper.showError(context, 'Greška pri plaćanju: $errorMessage');
        } else {
          NotificationHelper.showApiError(context, e);
        }
      }
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _processPayPalPayment() async {
    print('Starting PayPal payment process...');
    
    if (_paymentResponse == null) {
      print('ERROR: PaymentResponse is null');
      NotificationHelper.showError(context, 'Greška: Narudžba nije kreirana');
      return;
    }

    print('PaymentResponse received: ${_paymentResponse!.toJson()}');

    // Check if we have a valid approval URL from the backend
    if (_paymentResponse!.approvalUrl == null || _paymentResponse!.approvalUrl!.isEmpty) {
      print('ERROR: No PayPal approval URL provided by backend');
      NotificationHelper.showError(context, 'Greška: PayPal approval URL nije dostupan. Molimo kontaktirajte podršku.');
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final approvalUrl = _paymentResponse!.approvalUrl!;
      print('Using PayPal approval URL: $approvalUrl');
      
      // Launch PayPal URL in external browser
      print('Launching PayPal URL: $approvalUrl');
      
      final Uri paypalUri = Uri.parse(approvalUrl);
      if (await canLaunchUrl(paypalUri)) {
        final launched = await launchUrl(
          paypalUri,
          mode: LaunchMode.externalApplication, // Open in external browser
        );
        
        if (launched) {
          print('✅ PayPal URL launched successfully');
          
          // Extract PayPal order ID from transaction ID or use transaction ID directly
          final paypalOrderId = _paymentResponse!.transactionId;
          print('Starting PayPal payment monitoring for order: $paypalOrderId');
          
          // Start PayPal payment checking using the new provider
          _paypalProvider.startPaymentCheck(
            checkController: 'PayPalTest',
            orderIdForCheck: paypalOrderId,
            transactionIdForConfirm: _paymentResponse!.transactionId,
            confirmFn: (txId) async {
              await _orderProvider.confirmOrder(ConfirmOrderRequest(transactionId: txId));
            },
            onComplete: (success, message) async {
              if (!mounted) return;
              // Close waiting dialog if still open
              if (_isPayPalWaitingDialogOpen && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                _isPayPalWaitingDialogOpen = false;
              }
              if (success) {
                print('✅ PayPal payment completed successfully!');
                await _showThankYouDialogAndExit();
              } else {
                print('❌ PayPal payment failed: $message');
                NotificationHelper.showError(context, 'PayPal plaćanje neuspješno: $message');
              }
            },
          );
          
          // Show waiting dialog while user completes PayPal payment
          await _showPayPalWaitingDialog();
          
        } else {
          throw Exception('Ne mogu otvoriti PayPal URL');
        }
      } else {
        throw Exception('PayPal URL nije valjan ili se ne može otvoriti');
      }

  } catch (e) {
      print('Error processing PayPal payment: $e');
      if (mounted) {
    NotificationHelper.showApiError(context, e);
      }
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
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
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Čekanje PayPal plaćanja',
                        style: TextStyle(fontSize: 25),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Colors.blue.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Molimo završite plaćanje u PayPal-u',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aplikacija će automatski nastaviti kada završite plaćanje ili ga otkažete.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Ne zatvarajte aplikaciju tokom plaćanja',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (paypalProvider.isChecking)
                      Text(
                        'Provjeravam status plaćanja...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _paypalProvider.stopPaymentCheck();
                      Navigator.of(context).pop();
                      _isPayPalWaitingDialogOpen = false;
                      _showPayPalTimeoutDialog();
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

  

  Future<void> _showThankYouDialogAndExit() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Kupovina uspješna'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Hvala na kupovini! Vaša narudžba je potvrđena.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Iznos: ${widget.cart.finalAmount.toStringAsFixed(2)} KM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Početna'),
            ),
          ],
        );
      },
    );
  }

  void _showPayPalTimeoutDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PayPal plaćanje'),
          content: const Text(
            'Čekanje na potvrdu plaćanja je zaustavljeno. Ako ste završili plaćanje u pregledniku, status narudžbe će uskoro biti ažuriran.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('U redu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(
        showCart: false,
        showBackButton: true,
        cartItemsCount: widget.cart.totalItemsCount,
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
                    _buildOrderSummary(),
                    const SizedBox(height: 24),
                    _buildShippingSection(),
                    const SizedBox(height: 24),
                    _buildNotesSection(),
                    const SizedBox(height: 24),
                    _buildPaymentSection(),
                    const SizedBox(height: 32),
                    _buildPaymentButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderSummary() {
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
              'Pregled narudžbe',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Items count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Broj stavki:'),
                Text('${widget.cart.totalItemsCount}'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text('${widget.cart.totalAmount.toStringAsFixed(2)} KM'),
              ],
            ),
            
            // Membership discount
            if (widget.cart.hasActiveMembership == true) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_membership,
                        color: Colors.green.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Popust za članove:',
                        style: TextStyle(color: Colors.green.shade600),
                      ),
                    ],
                  ),
                  Text(
                    '-${widget.cart.membershipDiscount.toStringAsFixed(2)} KM',
                    style: TextStyle(color: Colors.green.shade600),
                  ),
                ],
              ),
            ],
            
            const Divider(),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ukupno:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.cart.finalAmount.toStringAsFixed(2)} KM',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
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
              'Dostava',
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
                hintText: 'Unesite adresu dostave',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
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
              ),
              hint: _isLoadingCities 
                ? const Text('Učitavanje gradova...')
                : const Text('Odaberite grad'),
              items: _isLoadingCities 
                ? [] 
                : (_cities.result ?? []).map((city) {
                    print('Creating dropdown item for city: ${city.id} - ${city.name}');
                    return DropdownMenuItem(
                      value: city.id,
                      child: Text(city.name),
                    );
                  }).toList(),
              onChanged: _isLoadingCities ? null : (value) {
                print('Selected city ID: $value');
                setState(() {
                  _selectedCityId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Grad je obavezan';
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
                hintText: 'Unesite poštanski broj',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
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
        print('Payment method changed to: $method');
        setState(() {
          _selectedPaymentMethod = method;
        });
        print('Payment method updated in state: $_selectedPaymentMethod');
      },
      cardNumberController: _cardNumberController,
      cardExpiryController: _cardExpiryController,
      cardCvcController: _cardCvcController,
      cardHolderNameController: _cardHolderNameController,
      isProcessing: _isLoading || _isProcessingPayment,
    );
  }

  Widget _buildNotesSection() {
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
              'Napomene (opciono)',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Unesite dodatne napomene za narudžbu...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || _isProcessingPayment) ? null : _processCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: (_isLoading || _isProcessingPayment)
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _selectedPaymentMethod == 'PayPal' 
                      ? 'Plati preko PayPal-a (${widget.cart.finalAmount.toStringAsFixed(2)} KM)'
                      : 'Završi narudžbu (${widget.cart.finalAmount.toStringAsFixed(2)} KM)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
