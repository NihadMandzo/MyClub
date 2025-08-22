# Stripe Payment Integration for MyClub Mobile

This implementation adds Stripe payment functionality to the MyClub mobile app for processing orders with credit card payments.

## Features Implemented

### 1. Request Models
- **PaymentRequest**: Abstract base class for payment requests with type (Stripe/PayPal), amount, and payment method
- **ShippingRequest**: Handles shipping information including address, city, and postal code
- **OrderItemInsertRequest**: Individual order items with product size, quantity, and unit price
- **OrderInsertRequest**: Complete order request extending PaymentRequest

### 2. Response Models
- **PaymentResponse**: Handles Stripe payment response with transaction ID, client secret, and payment URL

### 3. Providers
- **OrderProvider**: Extended with `placeOrder()` method to handle order placement
- **CityProvider**: New provider to fetch available cities for shipping

### 4. Screens
- **CheckoutScreen**: Complete checkout flow with:
  - Order summary with membership discounts
  - Shipping information form
  - Payment method selection (Stripe/PayPal)
  - Notes section
- **StripePaymentScreen**: Secure card payment form with:
  - Card number, expiry, CVV, and cardholder name
  - Real-time input formatting
  - Stripe SDK integration for secure payment processing

### 5. Cart Integration
- Updated CartScreen to navigate to checkout instead of showing placeholder
- Maintains cart state throughout checkout process

## Dependencies Added

```yaml
dependencies:
  flutter_stripe: ^10.1.1
```

## Setup Required

### 1. Stripe Configuration
Update `main.dart` with your actual Stripe publishable key:
```dart
Stripe.publishableKey = 'pk_test_your_actual_publishable_key';
```

### 2. Backend API Endpoints
The implementation expects these backend endpoints:
- `POST /api/Order` - Place order and create payment intent
- `GET /api/City` - Get list of cities for shipping

### 3. Backend Request Format
The OrderInsertRequest sent to backend follows this structure:
```json
{
  "userId": 123,
  "shipping": {
    "shippingAddress": "123 Main St",
    "cityId": 1,
    "shippingPostalCode": "12345"
  },
  "notes": "Special instructions",
  "items": [
    {
      "productSizeId": 456,
      "quantity": 2,
      "unitPrice": 25.00
    }
  ],
  "type": "Stripe",
  "amount": 50.00,
  "paymentMethod": "Stripe"
}
```

### 4. Backend Response Format
Expected PaymentResponse from backend:
```json
{
  "transactionId": "pi_1234567890",
  "clientSecret": "pi_1234567890_secret_abc123",
  "paymentUrl": null
}
```

## Usage Flow

1. **Cart Review**: User reviews items in cart
2. **Checkout**: User taps "Nastavi na plaćanje" to proceed to checkout
3. **Shipping Info**: User enters shipping address and selects city
4. **Payment Method**: User selects Stripe (PayPal disabled for now)
5. **Order Creation**: Order is placed on backend, payment intent created
6. **Card Payment**: User enters card details on secure Stripe form
7. **Payment Processing**: Stripe processes payment with 3D Secure if needed
8. **Confirmation**: User receives confirmation and returns to home

## Security Features

- Card details are processed directly by Stripe SDK (never stored locally)
- PCI DSS compliant payment processing
- 3D Secure authentication support
- Input validation and error handling
- Secure token-based API communication

## Future Enhancements

1. **PayPal Integration**: Complete PayPal payment flow
2. **Apple Pay/Google Pay**: Add digital wallet support
3. **Order Tracking**: Real-time order status updates
4. **Payment History**: View past payments and orders
5. **Saved Cards**: Allow users to save cards for future purchases

## Error Handling

The implementation includes comprehensive error handling for:
- Network connectivity issues
- Invalid card details
- Payment failures
- Backend API errors
- Stripe-specific errors with user-friendly messages

## Testing

To test the Stripe integration:
1. Use Stripe test card numbers (4242 4242 4242 4242)
2. Any future expiry date (MM/YY format)
3. Any 3-digit CVV
4. Monitor Stripe dashboard for test transactions
