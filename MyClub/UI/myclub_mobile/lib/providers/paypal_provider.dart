import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utility/api_config.dart';
import '../models/responses/paypal_check_response.dart';
import 'auth_provider.dart';
import 'base_provider.dart';

class PayPalProvider with ChangeNotifier {
  static String? baseUrl;
  static AuthProvider? _globalAuthProvider;
  late BuildContext context;
  AuthProvider? authProvider;
  
  Timer? _checkTimer;
  bool _isChecking = false;
  String? _currentOrderId; // PayPal order id used for check
  String? _transactionIdForConfirm; // transaction id used for confirm
  String? _checkController; // API controller name for check endpoint
  Future<void> Function(String transactionId)? _confirmFn; // callback to confirm
  Function(bool success, String? message)? _onPaymentComplete;

  PayPalProvider() {
    baseUrl = ApiConfig.baseUrl;
  }

  /// Set global auth provider for use across all providers
  static void setGlobalAuthProvider(AuthProvider authProvider) {
    _globalAuthProvider = authProvider;
  }

  void setContext(BuildContext context) {
    this.context = context;
    authProvider = BaseProvider.getGlobalAuthProvider();
  }

  /// Start checking PayPal payment status every 30 seconds
  void startPaymentCheck({
    required String checkController,
    required String orderIdForCheck,
    required String transactionIdForConfirm,
    required Future<void> Function(String transactionId) confirmFn,
    required Function(bool success, String? message) onComplete,
  }) {
    print('Starting PayPal payment check for order: $orderIdForCheck on controller: $checkController');
    
    // Stop any existing timer
    stopPaymentCheck(notify: false);
    
    _checkController = checkController;
    _currentOrderId = orderIdForCheck;
    _transactionIdForConfirm = transactionIdForConfirm;
    _confirmFn = confirmFn;
    _onPaymentComplete = onComplete;
    _isChecking = true;
    
    // Start periodic check every 30 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkPaymentStatus();
    });
    
    // Also check immediately
    _checkPaymentStatus();
    
    notifyListeners();
  }

  /// Stop the payment checking timer
  void stopPaymentCheck({bool notify = true}) {
    print('Stopping PayPal payment check');
    _checkTimer?.cancel();
    _checkTimer = null;
    _isChecking = false;
    _currentOrderId = null;
    if (notify) notifyListeners();
  }

  /// Check the PayPal payment status
  Future<void> _checkPaymentStatus() async {
    if (_currentOrderId == null) {
      print('No order ID to check');
      return;
    }

    try {
      print('Checking PayPal payment status for order: $_currentOrderId');
      
  final controller = _checkController ?? 'PayPalTest';
  final url = '${baseUrl}${controller}/check/$_currentOrderId';
      final uri = Uri.parse(url);
      final headers = _createHeaders();

      print('PayPal check URL: $url');
      print('PayPal check headers: $headers');

      final response = await http.get(uri, headers: headers);
      
      print('PayPal check response status: ${response.statusCode}');
      print('PayPal check response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paypalResponse = PayPalCheckResponse.fromJson(data);
        
        print('PayPal order ID: ${paypalResponse.orderId}, Status: ${paypalResponse.status}');
        
        if (paypalResponse.isApproved) {
          print('✅ PayPal payment approved! Confirming payment...');
          
          // Stop checking
          stopPaymentCheck();
          
          // Send confirm request to backend via provided callback
          await _confirmPayment();

        } else {
          print('PayPal payment status: ${paypalResponse.status} (still waiting...)');
        }
        
      } else if (response.statusCode == 404) {
        print('PayPal order not found or not ready yet');
        // Continue checking
      } else {
        print('PayPal check failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
        
        // Don't stop on error - keep trying for network issues
      }
      
    } catch (e) {
      print('Error checking PayPal payment status: $e');
      
      // Don't stop on error - keep trying for network issues
      // The timer will continue and try again in 30 seconds
    }
  }

  /// Send confirm request to backend via provided confirm function
  Future<void> _confirmPayment() async {
    try {
      final transactionId = _transactionIdForConfirm;
      if (transactionId == null || transactionId.isEmpty) {
        throw Exception('Missing transaction id for confirmation');
      }
      final fn = _confirmFn;
      if (fn == null) {
        throw Exception('Missing confirmation executor');
      }
      print('Sending confirmation for transaction: $transactionId');
      await fn(transactionId);

      print('✅ PayPal payment confirmed successfully via OrderProvider!');
      _onPaymentComplete?.call(true, 'PayPal payment confirmed successfully');
  // Clear callback after successful completion to avoid duplicate calls
  _onPaymentComplete = null;
    } catch (e) {
      print('Error confirming PayPal payment via OrderProvider: $e');
      _onPaymentComplete?.call(false, 'Error confirming payment: $e');
    }
  }

  /// Create HTTP headers with authorization
  Map<String, String> _createHeaders() {
    var headers = {
      "Content-Type": "application/json",
    };
    
    AuthProvider? auth = authProvider ?? _globalAuthProvider;
    
    if (auth?.token != null) {
      headers["Authorization"] = "Bearer ${auth!.token}";
      print("Including Authorization header for PayPal request");
    } else {
      print("Warning: No authorization token available for PayPal request");
    }

    return headers;
  }

  /// Get current checking status
  bool get isChecking => _isChecking;
  
  /// Get current order ID being checked
  String? get currentOrderId => _currentOrderId;

  @override
  void dispose() {
  // Avoid notifying listeners during widget tree disposal
  stopPaymentCheck(notify: false);
    super.dispose();
  }
}
