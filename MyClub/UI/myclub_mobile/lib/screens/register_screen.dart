import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/requests/user_upsert_request.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';

/// Registration screen for new users
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registracija'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveHelper.pagePadding(context),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 30),
              _buildRegistrationForm(context),
              const SizedBox(height: 20),
              _buildRegisterButton(context),
              const SizedBox(height: 20),
              _buildLoginLink(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the header with title and subtitle
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.person_add,
          size: ResponsiveHelper.iconSize(context) + 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Kreiraj novi račun',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 24),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unesite svoje podatke za registraciju',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 16),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build the registration form
  Widget _buildRegistrationForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // First Name
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'Ime *',
              hintText: 'Unesite ime',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ime je obavezno';
              }
              if (value.length > 50) {
                return 'Ime ne može biti duže od 50 karaktera';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: 16),
          
          // Last Name
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Prezime *',
              hintText: 'Unesite prezime',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Prezime je obavezno';
              }
              if (value.length > 50) {
                return 'Prezime ne može biti duže od 50 karaktera';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: 16),
          
          // Username
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Korisničko ime *',
              hintText: 'Unesite korisničko ime',
              prefixIcon: const Icon(Icons.account_circle_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Korisničko ime je obavezno';
              }
              if (value.length > 100) {
                return 'Korisničko ime ne može biti duže od 100 karaktera';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: 16),
          
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email *',
              hintText: 'Unesite email adresu',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email je obavezan';
              }
              if (value.length > 100) {
                return 'Email ne može biti duži od 100 karaktera';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Unesite ispravnu email adresu';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: 16),
          
          // Phone (optional)
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Broj telefona',
              hintText: 'Unesite broj telefona (opcionalno)',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length > 20) {
                return 'Broj telefona ne može biti duži od 20 karaktera';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: 16),
          
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Lozinka *',
              hintText: 'Unesite lozinku (minimalno 6 karaktera)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lozinka je obavezna';
              }
              if (value.length < 6) {
                return 'Lozinka mora imati najmanje 6 karaktera';
              }
              if (value.length > 100) {
                return 'Lozinka ne može biti duža od 100 karaktera';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: 16),
          
          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Potvrdi lozinku *',
              hintText: 'Ponovite lozinku',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Potvrda lozinke je obavezna';
              }
              if (value != _passwordController.text) {
                return 'Lozinke se ne poklapaju';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
          ),
        ],
      ),
    );
  }

  /// Build the register button
  Widget _buildRegisterButton(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 45 : 50,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Registriraj se',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, base: 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// Build the login link
  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Već imate račun? ',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 14),
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Prijavite se',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 14),
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Handle registration action
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Create the registration request
    final request = UserUpsertRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      isActive: true,
      roleId: null, // Let the backend set the default role
    );

    try {
      final success = await authProvider.register(request);
      
      if (success && mounted) {
        NotificationHelper.showSuccess(
          context, 
          'Registracija uspješna! Pokušajte se prijaviti.'
        );
        
        // Go back to login screen and auto-fill username
        Navigator.pop(context, _usernameController.text.trim());
      } else if (mounted) {
        final errorMessage = authProvider.errorMessage ?? 'Greška pri registraciji';
        NotificationHelper.showError(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showApiError(context, e, 'registraciji');
      }
    }
  }
}
