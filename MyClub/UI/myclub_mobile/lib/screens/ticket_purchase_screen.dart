import 'package:flutter/material.dart';
import 'package:myclub_mobile/providers/match_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:url_launcher/url_launcher.dart';
import '../models/responses/match_response.dart';
import '../models/responses/match_ticket_response.dart';
import '../models/responses/payment_response.dart';
import '../models/requests/ticket_purchase_request.dart';
import '../providers/auth_provider.dart';
import '../providers/paypal_provider.dart';
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
  late PayPalProvider _paypalProvider;

  // Card form controllers
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvcController = TextEditingController();
  final _cardHolderNameController = TextEditingController();

  // Form data
  String _selectedPaymentMethod = '';
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  bool _isPayPalWaitingDialogOpen = false;
  
  // Payment data
  PaymentResponse? _paymentResponse;
  String? _stripePaymentMethodId;

  @override
  void initState() {
    super.initState();
    _matchProvider = context.read<MatchProvider>();
    _authProvider = context.read<AuthProvider>();
  _paypalProvider = context.read<PayPalProvider>();
    _matchProvider.setContext(context);
  _paypalProvider.setContext(context);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    _cardHolderNameController.dispose();
  _paypalProvider.stopPaymentCheck(notify: false);
    super.dispose();
  }

  Future<void> _processTicketPurchase() async {
    print('=== TICKET PURCHASE BUTTON PRESSED ===');
    print('Form validation: ${_formKey.currentState?.validate()}');
    print('Selected payment method: $_selectedPaymentMethod');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    // Ensure payment method selected
    if (_selectedPaymentMethod.isEmpty) {
      print('No payment method selected');
      NotificationHelper.showError(context, 'Molimo odaberite način plaćanja');
      return;
    }

    print('✅ Validation passed, proceeding with payment method: $_selectedPaymentMethod');

    // For Stripe payments, we need the payment method first
    if (_selectedPaymentMethod == 'Stripe') {
      // Re-run validation to show inline errors for card fields
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

      if (!mounted) return;
      if (_selectedPaymentMethod == 'Stripe') {
        await _processStripePayment();
      } else if (_selectedPaymentMethod == 'PayPal') {
        await _processPayPalPayment();
      } else {
        NotificationHelper.showSuccess(context, 'Karta je rezervisana uspješno!');
      }
    } catch (e) {
      print('Error in _processTicketPurchase: $e');
      if (mounted) {
        NotificationHelper.showApiError(context, e, 'obradi rezervacije karte');
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

      print('Ticket PaymentIntent status: ${intent.status}');
      if (intent.status == stripe.PaymentIntentsStatus.Succeeded) {
        // Confirm ticket purchase on backend
        await _matchProvider.confirmOrder(_paymentResponse!.transactionId);
        if (mounted) {
          NotificationHelper.showSuccess(context, 'Plaćanje uspješno! Karta je kupljena.');
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
          final errorMessage = e.error.localizedMessage ?? e.error.message;
          NotificationHelper.showError(context, 'Provjerite vaše podatke');
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
      final uri = Uri.parse(approvalUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Ne mogu otvoriti PayPal URL');

      _paypalProvider.startPaymentCheck(
        checkController: 'PayPalTest',
        orderIdForCheck: _paymentResponse!.transactionId,
        transactionIdForConfirm: _paymentResponse!.transactionId,
        confirmFn: (txId) async {
          // Confirm endpoint expects plain string body already
          await _matchProvider.confirmOrder(txId);
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
                title: Row(children: const [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Expanded(child: Text('Čekanje PayPal plaćanja', overflow: TextOverflow.ellipsis))]),
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
          content: const Text('Hvala! Karta je kupljena.'),
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
