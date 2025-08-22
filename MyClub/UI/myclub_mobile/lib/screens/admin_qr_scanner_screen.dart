import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myclub_mobile/providers/match_provider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utility/auth_helper.dart';

class AdminQRScannerScreen extends StatefulWidget {
  const AdminQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AdminQRScannerScreenState();
}

class _AdminQRScannerScreenState extends State<AdminQRScannerScreen> {
  BarcodeCapture? result;
  MobileScannerController? controller;
  bool isLoading = false;
  String? lastScannedData;
  String? validationMessage;
  bool? isValid;

  late MatchProvider _matchProvider;

  @override
  void initState() {
    super.initState();
    _matchProvider = MatchProvider();
    controller = MobileScannerController();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set context for the match provider
    _matchProvider.setContext(context);
  }

  // No need for reassemble method with mobile_scanner
  @override
  void reassemble() {
    super.reassemble();
    // mobile_scanner handles platform differences automatically
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Check if user is admin
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Text(
            'Access Denied: Admin privileges required',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Administrator title and logout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1976D2),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.account_circle, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          
            // QR Scanner section
            Expanded(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // QR Scanner view - centered
                      Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: _buildQrView(context),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Validation result
                      if (validationMessage != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          decoration: BoxDecoration(
                            color: isValid == true ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isValid == true ? Icons.check_circle : Icons.error,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isValid == true ? 'Validna' : 'Nevalidna',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (isLoading)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Provjeram...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Continue scanning button (shown after validation)
                      if (validationMessage != null && !isLoading)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                result = null;
                                validationMessage = null;
                                isValid = null;
                                lastScannedData = null;
                              });
                              controller?.start();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Nastavi skeniranje',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 40),
                      
                      // Flash control
                      IconButton(
                        onPressed: () async {
                          await controller?.toggleTorch();
                        },
                        icon: const Icon(
                          Icons.flash_auto,
                          color: Color(0xFF1976D2),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _onBarcodeDetect,
        ),
        // Custom scanning indicator
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && !isLoading) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null && barcode.rawValue != lastScannedData) {
        setState(() {
          result = capture;
          lastScannedData = barcode.rawValue;
          isLoading = true;
          validationMessage = null;
          isValid = null;
        });
        
        // Stop camera while processing
        controller?.stop();
        _validateTicket(barcode.rawValue!);
      }
    }
  }

  Future<void> _validateTicket(String qrData) async {
    try {
      final response = await _matchProvider.validateTicket(qrData);

      setState(() {
        isLoading = false;
        isValid = response.isValid;
        validationMessage = response.message;
      });
      
      // Show a snackbar with the result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: response.isValid ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isValid = false;
        validationMessage = 'Greška: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška validacije: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Handle logout with confirmation
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Jeste li sigurni da se želite odjaviti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Odjavi se'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      await AuthHelper.clearAuthData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uspješno ste se odjavili.')),
        );
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
