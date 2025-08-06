import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myclub_desktop/models/order.dart';
import 'package:myclub_desktop/providers/order_provider.dart';
import 'package:myclub_desktop/utilities/dialog_utility.dart';
import 'package:myclub_desktop/utilities/notification_utility.dart';
import 'package:provider/provider.dart';

class OrderDetailsDialog extends StatefulWidget {
  final Order order;

  const OrderDetailsDialog({
    Key? key,
    required this.order,
  }) : super(key: key);
  
  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  late String _selectedStatus;
  bool _isUpdating = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
        _selectedStatus = widget.order.orderState;
  }

  // Get available next statuses based on current status
  List<String> _getAvailableNextStatuses() {
    if (_selectedStatus == 'Procesiranje') {
      return ['Procesiranje', 'Potvrđeno', 'Otkazano'];
    } else if (_selectedStatus == 'Potvrđeno') {
      return ['Potvrđeno', 'Dostava', 'Otkazano'];
    } else if (_selectedStatus == 'Dostava') {
      return ['Dostava', 'Završeno'];
    } else if (_selectedStatus == 'Završeno') {
      return ['Završeno'];
    } else if (_selectedStatus == 'Otkazano') {
      return ['Otkazano'];
    } else {
      return [_selectedStatus];
    }
  }

  // Update order status
  Future<void> _updateOrderStatus() async {
    if (_selectedStatus == widget.order.orderState) {
      return;
    }

    // Show confirmation dialog using DialogUtility
    final shouldProceed = await DialogUtility.showConfirmation(
      context,
      title: 'Potvrda promjene statusa',
      message: 'Jeste li sigurni da želite promijeniti status narudžbe iz "${widget.order.orderState}" u "${_selectedStatus}"?',
      confirmLabel: 'Potvrdi',
      cancelLabel: 'Odustani',
      confirmColor: Colors.blue,
    );

    if (!shouldProceed) {
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.updateOrderStatus(
        orderId: widget.order.id,
        newStatus: _selectedStatus,
      );
      
      // Show success notification
      NotificationUtility.showSuccess(
        context, 
        message: 'Status narudžbe je uspješno promijenjen u "${_selectedStatus}"'
      );
      
      // Success - close dialog
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate update was successful
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isUpdating = false;
      });
      
      // Show error notification
      NotificationUtility.showError(
        context, 
        message: 'Greška prilikom promjene statusa: ${e.toString()}'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.8;
    final availableStatuses = _getAvailableNextStatuses();

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
                  'Order #${widget.order.orderNumber ?? widget.order.id.toString()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      items: availableStatuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        }
                      },
                    ),
                    if (_selectedStatus != widget.order.orderState)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : _updateOrderStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: _isUpdating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Ažuriraj'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
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
                                  buildInfoItem('Kupac', widget.order.userFullName),
                                  buildInfoItem('Datum narudžbe',
                                      DateFormat('MMM dd, yyyy').format(widget.order.orderDate)),
                                  if (widget.order.shippedDate != null)
                                    buildInfoItem('Datum slanja',
                                        DateFormat('MMM dd, yyyy').format(widget.order.shippedDate!)),
                                  if (widget.order.deliveredDate != null)
                                    buildInfoItem('Datum isporuke',
                                        DateFormat('MMM dd, yyyy').format(widget.order.deliveredDate!)),
                                  buildInfoItem('Metoda Plačanja', widget.order.paymentMethod),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.order.shippingAddress != null)
                                    buildInfoItem('Adresa dostave', widget.order.shippingAddress!),
                                  if (widget.order.shippingCity != null)
                                    buildInfoItem('Grad', widget.order.shippingCity!),
                                  if (widget.order.shippingPostalCode != null)
                                    buildInfoItem('Poštanski broj', widget.order.shippingPostalCode!),
                                  if (widget.order.shippingCountry != null)
                                    buildInfoItem('Zemlja', widget.order.shippingCountry!),
                                  if (widget.order.notes != null && widget.order.notes!.isNotEmpty)
                                    buildInfoItem('Napomene', widget.order.notes!),
                                  if (widget.order.shippingAddress == null && 
                                      widget.order.shippingCity == null && 
                                      widget.order.shippingPostalCode == null && 
                                      widget.order.shippingCountry == null)
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
                          itemCount: widget.order.orderItems.length,
                          itemBuilder: (context, index) {
                            final item = widget.order.orderItems[index];
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
                                  '\$${widget.order.originalAmount.toStringAsFixed(2)}'),
                              if (widget.order.discountAmount > 0) ...[
                                buildSummaryRow('Popust',
                                    '-\$${widget.order.discountAmount.toStringAsFixed(2)}'),
                                if (widget.order.hasMembershipDiscount)
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
                                '\$${widget.order.totalAmount.toStringAsFixed(2)}',
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
