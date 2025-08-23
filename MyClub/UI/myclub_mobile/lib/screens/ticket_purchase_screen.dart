import 'package:flutter/material.dart';
import 'package:myclub_mobile/providers/match_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../models/responses/match_response.dart';
import '../models/responses/match_ticket_response.dart';
import '../models/responses/payment_response.dart';
import '../models/requests/ticket_purchase_request.dart';
import '../models/requests/confirm_order_request.dart';
import '../providers/auth_provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../widgets/top_navbar.dart';
import '../widgets/payment_section_widget.dart';

/// Screen for purchasing match tickets
class TicketPurchaseScreen extends StatefulWidget {
  final MatchResponse match;
  final MatchTicketResponse ticket;

  const TicketPurchaseScreen({
    super.key,
    required this.match,
    required this.ticket,
  });

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late MatchProvider _matchProvider;
  late AuthProvider _authProvider;

  // Card form controllers
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvcController = TextEditingController();
  final _cardHolderNameController = TextEditingController();

  // Form data
  String _selectedPaymentMethod = 'Stripe';
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  
  // Payment data
  PaymentResponse? _paymentResponse;
  String? _stripePaymentMethodId;

  @override
  void initState() {
    super.initState();
    _matchProvider = context.read<MatchProvider>();
    _authProvider = context.read<AuthProvider>();
    _matchProvider.setContext(context);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }

  Future<void> _processTicketPurchase() async {
    if (!_formKey.currentState!.validate()) return;

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

      // Determine payment method value
      String? paymentMethodValue;
      if (_selectedPaymentMethod == 'Stripe' && _stripePaymentMethodId != null) {
        paymentMethodValue = _stripePaymentMethodId; // Use Stripe payment method ID
      } else {
        paymentMethodValue = _selectedPaymentMethod; // Use "PayPal" for PayPal
      }

      // Calculate total amount
      final totalAmount = widget.ticket.price;

      // Create ticket purchase request (you'll need to create this model)
      final purchaseRequest = TicketPurchaseRequest(
        matchTicketId: widget.ticket.id,
        type: _selectedPaymentMethod, // This tells backend if it's Stripe or PayPal
        amount: totalAmount,
        paymentMethod: paymentMethodValue, // This contains the actual payment method ID from Stripe
      );

      // Purchase ticket and get payment response
      print('Purchasing ticket with request: ${purchaseRequest.toJson()}');
      final paymentResponse = await _matchProvider.purchaseTicket(purchaseRequest);
      print('Ticket purchase initiated, payment response received: ${paymentResponse.toJson()}');

      setState(() {
        _paymentResponse = paymentResponse;
      });

      if (mounted) {
        if (_selectedPaymentMethod == 'Stripe') {
          // Now process the Stripe payment
          await _processStripePayment();
        } else {
          NotificationHelper.showSuccess(context, 'Karta je rezervisana uspješno!');
        }
      }
    } catch (e) {
      print('Error in _processTicketPurchase: $e');
      if (mounted) {
        NotificationHelper.showError(context, 'Greška pri kupovini karte: $e');
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
      _stripePaymentMethodId = 'pm_test_ticket_${widget.ticket.id}'; // Unique test ID for ticket

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
      print('Simulating Stripe payment confirmation for ticket...');
      print('Payment Method ID: $_stripePaymentMethodId');
      print('Client Secret: ${_paymentResponse!.clientSecret}');

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Confirm ticket purchase on backend
      final confirmRequest = ConfirmOrderRequest(
        transactionId: _paymentResponse!.transactionId,
      );

      print('Confirming ticket purchase on backend...');
      await _matchProvider.confirmOrder(confirmRequest.transactionId);

      if (mounted) {
        NotificationHelper.showSuccess(context, 'Plaćanje uspješno! Karta je kupljena.');
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

  double get totalAmount => widget.ticket.price;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(
        showCart: false,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.pagePadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMatchInfo(),
              const SizedBox(height: 24),
              _buildTicketInfo(),
              const SizedBox(height: 24),
              _buildPaymentSection(),
              const SizedBox(height: 24),
              _buildPurchaseButton(totalAmount),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchInfo() {
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
                  Icons.sports_soccer,
                  color: Theme.of(context).primaryColor,
                  size: ResponsiveHelper.iconSize(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Detalji utakmice',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Teams
            Text(
              '${widget.match.clubName} vs ${widget.match.opponentName}',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Date and time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: ResponsiveHelper.iconSize(context) - 4,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(widget.match.matchDate)} u ${_formatTime(widget.match.matchDate)}',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: ResponsiveHelper.iconSize(context) - 4,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  widget.match.location,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketInfo() {
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
                  Icons.confirmation_number,
                  color: Theme.of(context).primaryColor,
                  size: ResponsiveHelper.iconSize(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Informacije o karti',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sector
            _buildTicketDetailRow('Sektor:', widget.ticket.stadiumSector?.code ?? 'N/A'),
            _buildTicketDetailRow('Strana:', widget.ticket.stadiumSector?.sideName ?? 'N/A'),
            _buildTicketDetailRow('Cijena po karti:', '${widget.ticket.price.toStringAsFixed(2)} KM'),
            _buildTicketDetailRow('Dostupno karata:', '${widget.ticket.availableQuantity}'),
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

  Widget _buildPurchaseButton(double totalAmount) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || _isProcessingPayment) ? null : _processTicketPurchase,
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
                    'Kupi kartu (${totalAmount.toStringAsFixed(2)} KM)',
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

  Widget _buildTicketDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date to dd.MM.yyyy format
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Format time to HH:mm format
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
