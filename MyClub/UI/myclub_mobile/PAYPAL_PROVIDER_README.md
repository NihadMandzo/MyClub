# PayPal Provider Documentation

## Overview
The `PayPalProvider` is a Flutter provider that handles PayPal payment verification by periodically checking the payment status and automatically confirming approved payments.

## Features
- ✅ Checks PayPal payment status every 30 seconds
- ✅ Automatically stops checking when payment is approved or times out
- ✅ Confirms payment with backend when status is "APPROVED"
- ✅ Provides status updates through callback functions
- ✅ Integrates with existing authentication system

## API Endpoints
The provider uses the following backend endpoints:

### Check Payment Status
- **URL**: `http://localhost:5206/api/PayPalTest/check/{orderId}`
- **Method**: GET
- **Response**: 
```json
{
  "orderId": "8D611835RM453231P",
  "status": "APPROVED"
}
```

### Confirm Payment
- **URL**: `http://localhost:5206/api/PayPalTest/confirm`
- **Method**: POST
- **Body**: 
```json
{
  "orderId": "8D611835RM453231P"
}
```

## Usage

### 1. Initialize the Provider
The provider is automatically registered in `main.dart` and available throughout the app.

### 2. Start Payment Checking
```dart
// Get the provider
final paypalProvider = context.read<PayPalProvider>();

// Start checking payment status
paypalProvider.startPaymentCheck(
  orderId, // PayPal order ID from the payment response
  (success, message) {
    if (success) {
      // Payment completed successfully
      print('Payment successful: $message');
      // Navigate to success screen or show success message
    } else {
      // Payment failed or timed out
      print('Payment failed: $message');
      // Show error message to user
    }
  }
);
```

### 3. Stop Payment Checking
```dart
// Stop the payment check (optional - stops automatically on completion)
paypalProvider.stopPaymentCheck();
```

### 4. Monitor Status
```dart
// Listen to provider changes
Consumer<PayPalProvider>(
  builder: (context, paypalProvider, child) {
    if (paypalProvider.isChecking) {
      return Text('Checking payment status...');
    }
    return Text('No active payment check');
  }
)
```

## Integration Example

The `CheckoutScreen` shows how to integrate the provider:

```dart
// After PayPal URL is launched
final paypalOrderId = _paymentResponse!.transactionId;

_paypalProvider.startPaymentCheck(paypalOrderId, (success, message) {
  if (mounted) {
    if (success) {
      NotificationHelper.showSuccess(context, 'PayPal payment successful!');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      NotificationHelper.showError(context, 'PayPal payment failed: $message');
    }
  }
});
```

## Configuration

### Check Interval
The provider checks every 30 seconds as requested. This can be modified in the provider:

```dart
// In PayPalProvider.startPaymentCheck()
_checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
  await _checkPaymentStatus();
});
```

### Backend URL
The base URL is configured in `ApiConfig.baseUrl`. The provider constructs the full URL as:
- Check: `{baseUrl}/api/PayPalTest/check/{orderId}`
- Confirm: `{baseUrl}/api/PayPalTest/confirm`

## Error Handling

The provider handles various error scenarios:
- **Network errors**: Continues checking and retries
- **404 errors**: Payment not ready yet, continues checking
- **Authentication errors**: Passes error to callback
- **Confirmation errors**: Reports to callback with error details

## State Management

The provider maintains:
- `isChecking`: Boolean indicating if actively checking
- `currentOrderId`: The order ID being monitored
- Timer for periodic checks
- Callback function for completion notification

## Cleanup

The provider automatically:
- Stops the timer when payment is completed
- Cleans up resources in the dispose method
- Can be manually stopped with `stopPaymentCheck()`

## Dependencies

- `http`: For API requests
- `dart:async`: For Timer functionality
- `flutter/material.dart`: For ChangeNotifier
- Custom models: `PayPalConfirmRequest`, `PayPalCheckResponse`
