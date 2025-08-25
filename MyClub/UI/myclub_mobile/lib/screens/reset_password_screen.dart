import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/requests/reset_password_request.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String username;
  
  const ResetPasswordScreen({
    super.key,
    required this.username,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Resetovanje lozinke',
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
            _buildResetPasswordForm(),
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
                    'Unesite kod iz emaila',
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
              'Poslali smo vam kod za resetovanje lozinke na email. Unesite kod i novu lozinku ispod.',
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

  Widget _buildResetPasswordForm() {
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
            initialValue: widget.username,
            enabled: false,
            decoration: InputDecoration(
              hintText: 'Vaše korisničko ime',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kod za resetovanje',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _resetCodeController,
            decoration: InputDecoration(
              hintText: 'Unesite 6-cifreni kod',
              prefixIcon: const Icon(Icons.security),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Kod za resetovanje je obavezan';
              }
              if (value.length != 6) {
                return 'Kod mora imati 6 cifara';
              }
              return null;
            },
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          Text(
            'Nova lozinka',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              hintText: 'Unesite novu lozinku',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nova lozinka je obavezna';
              }
              if (value.length < 6) {
                return 'Lozinka mora imati najmanje 6 znakova';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Potvrda nove lozinke',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Potvrdite novu lozinku',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Potvrda lozinke je obavezna';
              }
              if (value != _newPasswordController.text) {
                return 'Lozinke se ne podudaraju';
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
                    'Resetuj lozinku',
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final request = ResetPasswordRequest(
        username: widget.username,
        resetCode: _resetCodeController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      final success = await authProvider.resetPassword(request);

      if (success && mounted) {
        NotificationHelper.showSuccess(
          context, 
          'Lozinka je uspješno resetovana. Možete se prijaviti sa novom lozinkom.'
        );
        
        // Navigate back to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else if (mounted) {
        final errorMessage = authProvider.errorMessage ?? 'Greška pri resetovanju lozinke';
        NotificationHelper.showError(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showApiError(context, e, 'resetovanju lozinke');
      }
    }
  }
}
