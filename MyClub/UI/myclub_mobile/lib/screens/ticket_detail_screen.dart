import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/responses/user_ticket_response.dart';
import '../utility/responsive_helper.dart';

class TicketDetailScreen extends StatelessWidget {
  final UserTicketResponse ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: ResponsiveHelper.cardElevation(context),
        title: const Text(
          'Detalji ulaznice',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildTicketCard(context),
            const SizedBox(height: 30),
            _buildQRCode(context),
            const SizedBox(height: 30),
            _buildMatchDetails(context),
            const SizedBox(height: 20),
            _buildSeatDetails(context),
            const SizedBox(height: 20),
            _buildPurchaseDetails(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: ticket.isValid
                ? [Colors.green, Colors.green.withOpacity(0.8)]
                : [Colors.grey, Colors.grey.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              ticket.isValid ? Icons.confirmation_number : Icons.cancel,
              size: ResponsiveHelper.iconSize(context) + 10,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              ticket.opponentName,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 24),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ticket.formattedMatchDate,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 16),
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ticket.location,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 14),
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ticket.isValid ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ticket.isValid ? 'VAŽEĆA ULAZNICA' : 'NEWAŻEĆA ULAZNICA',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 12),
                  fontWeight: FontWeight.bold,
                  color: ticket.isValid ? Colors.green : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCode(BuildContext context) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'QR Kod ulaznice',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: ticket.qrCodeData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pokažite ovaj QR kod na ulazu',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: #${ticket.id.toString().padLeft(6, '0')}',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 12),
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchDetails(BuildContext context) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalji utakmice',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.sports_soccer,
              'Protivnik',
              ticket.opponentName,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Datum i vrijeme',
              ticket.formattedMatchDate,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.location_on,
              'Lokacija',
              ticket.location,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.confirmation_number,
              'ID utakmice',
              ticket.matchId.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatDetails(BuildContext context) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalji sjedišta',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.event_seat,
              'Sektor',
              ticket.sectorCode,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.stadium,
              'Strana stadiona',
              ticket.stadiumSide,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseDetails(BuildContext context) {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalji kupovine',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.receipt,
              'Ukupna cijena',
              '${ticket.totalPrice.toStringAsFixed(2)} KM',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Datum kupovine',
              ticket.formattedPurchaseDate,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.verified,
              'Status',
              ticket.isValid ? 'Važeća' : 'Neważeća',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 12),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 14),
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
