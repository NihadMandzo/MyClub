import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myclub_desktop/models/order.dart';

class OrderDetailsDialog extends StatelessWidget {
  final Order order;

  const OrderDetailsDialog({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.8;

    // Function to create info item
    Widget buildInfoItem(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
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

    // Function to create summary row
    Widget buildSummaryRow(String label, String value, {bool isBold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              ),
            ),
          ],
        ),
      );
    }

    // Function to get status text
    String getStatusText(OrderStatus status) {
      switch (status) {
        case OrderStatus.pending:
          return 'Pending';
        case OrderStatus.processing:
          return 'Processing';
        case OrderStatus.shipped:
          return 'Shipped';
        case OrderStatus.delivered:
          return 'Delivered';
        case OrderStatus.cancelled:
          return 'Cancelled';
        case OrderStatus.refunded:
          return 'Refunded';
      }
    }

    // Build status badge
    Widget statusBadge = (() {
      Color bgColor;
      Color textColor = Colors.white;
      String text = getStatusText(order.status);

      switch (order.status) {
        case OrderStatus.pending:
          bgColor = Colors.orange;
          break;
        case OrderStatus.processing:
          bgColor = Colors.blue;
          break;
        case OrderStatus.shipped:
          bgColor = Colors.indigo;
          break;
        case OrderStatus.delivered:
          bgColor = Colors.green;
          break;
        case OrderStatus.cancelled:
          bgColor = Colors.red;
          break;
        case OrderStatus.refunded:
          bgColor = Colors.purple;
          break;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    })();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber ?? order.id.toString()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                statusBadge,
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informacije o narudžbi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildInfoItem('Kupac', order.userFullName),
                                  buildInfoItem('Datum narudžbe',
                                      DateFormat('MMM dd, yyyy').format(order.orderDate)),
                                  if (order.shippedDate != null)
                                    buildInfoItem('Datum slanja',
                                        DateFormat('MMM dd, yyyy').format(order.shippedDate!)),
                                  if (order.deliveredDate != null)
                                    buildInfoItem('Datum isporuke',
                                        DateFormat('MMM dd, yyyy').format(order.deliveredDate!)),
                                  buildInfoItem('Metoda Plačanja', order.paymentMethod),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (order.shippingAddress != null)
                                    buildInfoItem('Adresa dostave', order.shippingAddress!),
                                  if (order.shippingCity != null)
                                    buildInfoItem('Grad', order.shippingCity!),
                                  if (order.shippingPostalCode != null)
                                    buildInfoItem('Poštanski broj', order.shippingPostalCode!),
                                  if (order.shippingCountry != null)
                                    buildInfoItem('Zemlja', order.shippingCountry!),
                                  if (order.notes != null && order.notes!.isNotEmpty)
                                    buildInfoItem('Napomene', order.notes!),
                                  if (order.shippingAddress == null && 
                                      order.shippingCity == null && 
                                      order.shippingPostalCode == null && 
                                      order.shippingCountry == null)
                                    const Text('Nema informacija o dostavi',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Order Items Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stavke narudžbe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: order.orderItems.length,
                          itemBuilder: (context, index) {
                            final item = order.orderItems[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Product Name
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    // Size
                                    Text(
                                      'Veličina: ${item.sizeName}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Quantity
                                    Text(
                                      'Količina: ${item.quantity}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Price info
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (item.discount != null) ...[
                                          Text(
                                            '\$${item.unitPrice.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              decoration: TextDecoration.lineThrough,
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          '\$${item.subtotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Totals Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pregled narudžbe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              buildSummaryRow('Prava cijena',
                                  '\$${order.originalAmount.toStringAsFixed(2)}'),
                              if (order.discountAmount > 0) ...[
                                buildSummaryRow('Popust',
                                    '-\$${order.discountAmount.toStringAsFixed(2)}'),
                                if (order.hasMembershipDiscount)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4, bottom: 8),
                                    child: Text(
                                      'Uključuje popust za članstvo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                              ],
                              const Divider(),
                              buildSummaryRow(
                                'Ukupno',
                                '\$${order.totalAmount.toStringAsFixed(2)}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zatvori'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
