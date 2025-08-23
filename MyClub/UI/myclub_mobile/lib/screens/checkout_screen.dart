import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myclub_mobile/models/responses/paged_result.dart';
import 'package:myclub_mobile/models/search_objects/base_search_object.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
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

  @override
  void initState() {
    super.initState();
    _orderProvider = context.read<OrderProvider>();
    _cityProvider = context.read<CityProvider>();
    _authProvider = context.read<AuthProvider>();
    _orderProvider.setContext(context);
    _cityProvider.setContext(context);
    _loadCities();
  }

  @override
  void dispose() {
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
        NotificationHelper.showError(context, 'Greška pri učitavanju gradova: $e');
      }
    } finally {
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCityId == null) {
      NotificationHelper.showError(context, 'Molimo odaberite grad');
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
      } else {
        paymentMethodValue = _selectedPaymentMethod; // Use "PayPal" for PayPal
      }

      // Create order request
      final orderRequest = OrderInsertRequest(
        userId: userId,
        shipping: shippingRequest,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        items: orderItems,
        type: _selectedPaymentMethod, // This tells backend if it's Stripe or PayPal
        amount: widget.cart.finalAmount,
        paymentMethod: paymentMethodValue, // This contains the actual payment method ID from Stripe
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
          // Now process the Stripe payment
          await _processStripePayment();
        } else {
          NotificationHelper.showSuccess(context, 'Narudžba je kreirana uspješno!');
        }
      }
    } catch (e) {
      print('Error in _processCheckout: $e');
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri kreiranju narudžbe: $e');
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
        NotificationHelper.showError(context, 'Greška pri kreiranju načina plaćanja: $e');
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
      // For the mock implementation, we'll simulate the payment confirmation
      print('Simulating Stripe payment confirmation...');
      print('Payment Method ID: $_stripePaymentMethodId');
      print('Client Secret: ${_paymentResponse!.clientSecret}');

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Confirm order on backend
      final confirmRequest = ConfirmOrderRequest(
        transactionId: _paymentResponse!.transactionId,
      );

      print('Confirming order on backend...');
      await _orderProvider.confirmOrder(confirmRequest);

      if (mounted) {
        NotificationHelper.showSuccess(context, 'Plaćanje uspješno! Narudžba je potvrđena.');
        // Navigate back to main screen or orders
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
                    'Završi narudžbu (${widget.cart.finalAmount.toStringAsFixed(2)} KM)',
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
