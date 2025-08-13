import 'package:flutter/material.dart';
import '../models/responses/match_response.dart';
import '../models/responses/match_ticket_response.dart';
import '../utility/responsive_helper.dart';

/// Dialog widget that displays detailed information about an upcoming match
/// including match details and available tickets with preview functionality
class MatchDialog extends StatelessWidget {
  final MatchResponse match;

  const MatchDialog({
    super.key,
    required this.match,
  });

  /// Show the match dialog
  static Future<void> show(BuildContext context, MatchResponse match) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return MatchDialog(match: match);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 700,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            _buildHeader(context),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match teams display
                    _buildTeamsSection(context),
                    
                    const SizedBox(height: 24),
                    
                    // Match details
                    _buildMatchDetails(context),
                    
                    const SizedBox(height: 24),
                    
                    // Description if available
                    if (match.description.isNotEmpty) ...[
                      _buildDescriptionSection(context),
                      const SizedBox(height: 24),
                    ],
                    
                    // Tickets section
                    _buildTicketsSection(context),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Build dialog header with title and close button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            color: Colors.white,
            size: ResponsiveHelper.iconSize(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Detalji utakmice',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build teams display section
  Widget _buildTeamsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Home team (club)
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    size: ResponsiveHelper.iconSize(context) + 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  match.clubName,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 16),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'DOMAĆI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.font(context, base: 10),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // VS separator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'VS',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 24),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formatTime(match.matchDate),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 14),
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Away team (opponent)
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    size: ResponsiveHelper.iconSize(context) + 16,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  match.opponentName,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, base: 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'GOSTI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.font(context, base: 10),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build match details section
  Widget _buildMatchDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informacije o utakmici',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Date and time
        _buildDetailItem(
          context,
          icon: Icons.calendar_today,
          title: 'Datum i vrijeme',
          value: '${_formatDate(match.matchDate)} u ${_formatTime(match.matchDate)}',
        ),
        
        const SizedBox(height: 12),
        
        // Location
        _buildDetailItem(
          context,
          icon: Icons.location_on,
          title: 'Lokacija',
          value: match.location,
        ),
        
        const SizedBox(height: 12),
        
        // Status
        _buildDetailItem(
          context,
          icon: Icons.info_outline,
          title: 'Status',
          value: match.status,
        ),
      ],
    );
  }

  /// Build description section
  Widget _buildDescriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opis',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            match.description,
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 14),
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Build tickets section
  Widget _buildTicketsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.confirmation_number,
              size: ResponsiveHelper.iconSize(context),
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Dostupne karte',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (match.tickets.isEmpty)
          _buildNoTicketsMessage(context)
        else
          ...match.tickets.map((ticket) => _buildTicketCard(context, ticket)),
      ],
    );
  }

  /// Build no tickets available message
  Widget _buildNoTicketsMessage(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: ResponsiveHelper.iconSize(context) + 8,
            color: Colors.orange[700],
          ),
          const SizedBox(height: 8),
          Text(
            'Trenutno nema dostupnih karata',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Karte će biti dostupne uskoro',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 14),
              color: Colors.orange[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build individual ticket card
  Widget _buildTicketCard(BuildContext context, MatchTicketResponse ticket) {
    final isAvailable = ticket.availableQuantity > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: ResponsiveHelper.cardElevation(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isAvailable ? Colors.green[200]! : Colors.red[200]!,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: isAvailable
              ? () => _showTicketPreview(context, ticket)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Sector name and status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.stadiumSector?.code ?? 'Nepoznat sektor',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (ticket.stadiumSector?.sideName.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              ticket.stadiumSector!.sideName,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.font(context, base: 12),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isAvailable ? 'DOSTUPNO' : 'RASPRODANO',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(context, base: 10),
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Price and availability info
                Row(
                  children: [
                    // Price
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '${ticket.price.toStringAsFixed(2)} BAM',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(context, base: 18),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Availability
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Dostupno: ${ticket.availableQuantity}',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(context, base: 14),
                            fontWeight: FontWeight.w600,
                            color: isAvailable ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        Text(
                          'od ${ticket.releasedQuantity}',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(context, base: 12),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (isAvailable) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showTicketPreview(context, ticket),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Pregled'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBuyTicketDialog(context, ticket),
                          icon: const Icon(Icons.shopping_cart, size: 16),
                          label: const Text('Kupi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build detail item row
  Widget _buildDetailItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: ResponsiveHelper.iconSize(context) - 4,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build action buttons at the bottom
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zatvori'),
            ),
          ),
          if (match.tickets.any((ticket) => ticket.availableQuantity > 0)) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAllTicketsPreview(context),
                icon: const Icon(Icons.confirmation_number, size: 16),
                label: const Text('Sve karte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Show ticket preview dialog
  void _showTicketPreview(BuildContext context, MatchTicketResponse ticket) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pregled karte - ${ticket.stadiumSector?.code ?? "Nepoznat sektor"}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTicketDetailRow('Sektor:', ticket.stadiumSector?.code ?? 'N/A'),
                _buildTicketDetailRow('Strana:', ticket.stadiumSector?.sideName ?? 'N/A'),
                _buildTicketDetailRow('Kapacitet sektora:', '${ticket.stadiumSector?.capacity ?? 0}'),
                _buildTicketDetailRow('Cijena:', '${ticket.price.toStringAsFixed(2)} BAM'),
                _buildTicketDetailRow('Dostupno karata:', '${ticket.availableQuantity}'),
                _buildTicketDetailRow('Ukupno izdato:', '${ticket.releasedQuantity}'),
                _buildTicketDetailRow('Korišteno:', '${ticket.usedQuantity}'),
                const SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zatvori'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showBuyTicketDialog(context, ticket);
              },
              child: const Text('Kupi kartu'),
            ),
          ],
        );
      },
    );
  }

  /// Show buy ticket dialog (placeholder)
  void _showBuyTicketDialog(BuildContext context, MatchTicketResponse ticket) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kupovina karte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction,
                size: 48,
                color: Colors.orange[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Funkcionalnost kupovine karata će biti implementirana uskoro.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 16),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Karta: ${ticket.stadiumSector?.code ?? "Nepoznat sektor"}\nCijena: ${ticket.price.toStringAsFixed(2)} BAM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, base: 14),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Razumijem'),
            ),
          ],
        );
      },
    );
  }

  /// Show all tickets preview
  void _showAllTicketsPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sve dostupne karte'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: match.tickets.where((t) => t.availableQuantity > 0).length,
              itemBuilder: (context, index) {
                final availableTickets = match.tickets.where((t) => t.availableQuantity > 0).toList();
                final ticket = availableTickets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(ticket.stadiumSector?.code ?? 'Nepoznat sektor'),
                    subtitle: Text('${ticket.price.toStringAsFixed(2)} BAM • Dostupno: ${ticket.availableQuantity}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showTicketPreview(context, ticket);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zatvori'),
            ),
          ],
        );
      },
    );
  }

  /// Build ticket detail row for preview
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
