import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../providers/user_provider.dart';
import '../models/requests/change_password_request.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
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
        elevation: ResponsiveHelper.cardElevation(context),
        title: const Text(
          'Promjena lozinke',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildInfoCard(),
              const SizedBox(height: 30),
              _buildPasswordField(
                controller: _oldPasswordController,
                labelText: 'Trenutna lozinka',
                obscureText: _obscureOldPassword,
                onToggleVisibility: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Unesite trenutnu lozinku';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _newPasswordController,
                labelText: 'Nova lozinka',
                obscureText: _obscureNewPassword,
                onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Unesite novu lozinku';
                  }
                  if (value.length < 6) {
                    return 'Lozinka mora sadržavati najmanje 6 znakova';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordController,
                labelText: 'Potvrda nove lozinke',
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Potvrdite novu lozinku';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Lozinke se ne podudaraju';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
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
                Icon(Icons.info_outline, 
                  color: Theme.of(context).primaryColor,
                  size: ResponsiveHelper.iconSize(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Napomene za promjenu lozinke',
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
              '• Nova lozinka mora imati najmanje 6 znakova\n'
              '• Unesite svoju trenutnu lozinku za potvrdu identiteta\n'
              '• Lozinka će biti promijenjena odmah po potvrdi',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required Function() onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Promijeni lozinku',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final request = ChangePasswordRequest(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      
      await userProvider.changePassword(request);
      
      if (mounted) {
        NotificationHelper.showSuccess(context, 'Lozinka je uspješno promijenjena');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      print('Error changing password: $e');
      if (mounted) {
        NotificationHelper.showApiError(context, e, 'promjeni lozinke');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
