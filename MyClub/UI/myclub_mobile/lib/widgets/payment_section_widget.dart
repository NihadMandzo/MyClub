import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utility/responsive_helper.dart';

// Custom input formatters for card fields
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

/// Reusable payment section widget for all purchase screens
class PaymentSectionWidget extends StatefulWidget {
  final String selectedPaymentMethod;
  final Function(String) onPaymentMethodChanged;
  final TextEditingController cardNumberController;
  final TextEditingController cardExpiryController;
  final TextEditingController cardCvcController;
  final TextEditingController cardHolderNameController;
  final bool isProcessing;

  const PaymentSectionWidget({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.cardNumberController,
    required this.cardExpiryController,
    required this.cardCvcController,
    required this.cardHolderNameController,
    this.isProcessing = false,
  });

  @override
  State<PaymentSectionWidget> createState() => _PaymentSectionWidgetState();
}

class _PaymentSectionWidgetState extends State<PaymentSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Način plaćanja',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Stripe expandable option
            _buildStripeOption(),
            
            const SizedBox(height: 8),
            
            // PayPal expandable option (disabled for now)
            _buildPayPalOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildStripeOption() {
    return ExpansionTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.credit_card,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Kreditna/Debitna kartica',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: widget.selectedPaymentMethod == 'Stripe' 
        ? const Text('Odabrano', style: TextStyle(color: Colors.green))
        : null,
      leading: Radio<String>(
        value: 'Stripe',
        groupValue: widget.selectedPaymentMethod,
        onChanged: widget.isProcessing ? null : (value) {
          widget.onPaymentMethodChanged(value!);
        },
      ),
      onExpansionChanged: widget.isProcessing ? null : (expanded) {
        if (expanded) {
          widget.onPaymentMethodChanged('Stripe');
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plaćanje kreditnom karticom preko Stripe platforme',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Sigurno i zaštićeno plaćanje',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Always show card form when Stripe is selected
              if (widget.selectedPaymentMethod == 'Stripe') ...[
                _buildCardForm(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Card Number
          TextFormField(
            controller: widget.cardNumberController,
            enabled: !widget.isProcessing,
            decoration: const InputDecoration(
              labelText: 'Broj kartice',
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icon(Icons.credit_card),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              CardNumberInputFormatter(),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Broj kartice je obavezan';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Cardholder Name
          TextFormField(
            controller: widget.cardHolderNameController,
            enabled: !widget.isProcessing,
            decoration: const InputDecoration(
              labelText: 'Ime vlasnika kartice',
              hintText: 'Ime kao na kartici',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ime vlasnika kartice je obavezno';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Expiry and CVC
          Row(
            children: [
              // Expiry Date
              Expanded(
                child: TextFormField(
                  controller: widget.cardExpiryController,
                  enabled: !widget.isProcessing,
                  decoration: const InputDecoration(
                    labelText: 'MM/YY',
                    hintText: '12/26',
                    prefixIcon: Icon(Icons.date_range),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    ExpiryDateInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Datum isteka je obavezan';
                    }
                    if (!value.contains('/') || value.length != 5) {
                      return 'Format: MM/YY';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // CVC
              Expanded(
                child: TextFormField(
                  controller: widget.cardCvcController,
                  enabled: !widget.isProcessing,
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    hintText: '123',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'CVC je obavezan';
                    }
                    if (value.length < 3) {
                      return 'CVC mora imati najmanje 3 cifre';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayPalOption() {
    return ExpansionTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payment,
            color: Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'PayPal (Uskoro dostupno)',
              style: TextStyle(color: Colors.grey.shade500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      leading: Radio<String>(
        value: 'PayPal',
        groupValue: widget.selectedPaymentMethod,
        onChanged: null, // Disabled for now
      ),
      onExpansionChanged: null, // Disabled for now
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                'PayPal integracija će biti dostupna uskoro',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Uskoro dostupno',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
