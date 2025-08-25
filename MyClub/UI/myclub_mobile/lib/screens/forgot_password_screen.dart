import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Zaboravljena lozinka',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            _buildInfoCard(),
            const SizedBox(height: 30),
            _buildForgotPasswordForm(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: ResponsiveHelper.cardElevation(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline, 
                  color: Theme.of(context).primaryColor,
                  size: ResponsiveHelper.iconSize(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Resetovanje lozinke',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Unesite korisničko ime i mi ćemo vam poslati email sa kodom za resetovanje lozinke.',
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, base: 14),
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Korisničko ime',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Unesite vaše korisničko ime',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Korisničko ime je obavezno';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Pošalji kod za resetovanje',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.forgotPassword(username);

      if (success && mounted) {
        NotificationHelper.showSuccess(
          context, 
          'Kod za resetovanje lozinke je poslan na vaš email'
        );
        
        // Navigate to reset password screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(username: username),
          ),
        );
      } else if (mounted) {
        final errorMessage = authProvider.errorMessage ?? 'Greška pri slanju koda za resetovanje';
        NotificationHelper.showError(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showApiError(context, e, 'slanju koda za resetovanje');
      }
    }
  }
}
