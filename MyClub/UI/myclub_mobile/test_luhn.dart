void main() {
  String cardNumber = '4000000000000003'; // Invalid - fails Luhn
  print('Testing card number: $cardNumber');
  
  // Luhn algorithm implementation from the code
  int sum = 0;
  bool alt = false;
  for (int i = cardNumber.length - 1; i >= 0; i--) {
    int n = int.parse(cardNumber[i]);
    print('Digit at position $i: $n');
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
      print('  After doubling and reducing: $n');
    }
    alt = !alt;
    sum += n;
    print('  Running sum: $sum');
  }
  print('Final sum: $sum');
  print('Sum % 10: ${sum % 10}');
  print('Is valid (sum % 10 == 0): ${sum % 10 == 0}');
}
