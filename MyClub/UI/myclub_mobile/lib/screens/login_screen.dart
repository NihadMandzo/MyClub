import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utility/responsive_helper.dart';
import '../utility/notification_helper.dart';
import '../utility/auth_helper.dart';
import 'register_screen.dart';

/// Login screen with username/password form and JWT authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveHelper.pagePadding(context),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              _buildHeader(context),
              SizedBox(height: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 40 : 60),
              _buildLoginForm(context),
              const SizedBox(height: 20),
              _buildLoginButton(context),
              const SizedBox(height: 20),
              _buildRegisterLink(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the header with logo and title
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Club logo
        Container(
          width: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 80 : 120,
          height: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 80 : 120,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sports_soccer,
            size: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 40 : 60,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // App title
        Text(
          'MyClub',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 32),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Dobrodošli u MyClub aplikaciju',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 16),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build the login form
  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Username field
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Korisničko ime',
              hintText: 'Unesite korisničko ime',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Korisničko ime je obavezno';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: 20),
          
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Lozinka',
              hintText: 'Unesite lozinku',
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
              if (value.length < 3) {
                return 'Lozinka mora imati najmanje 3 karaktera';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
          ),
        ],
      ),
    );
  }

  /// Build the login button
  Widget _buildLoginButton(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 45 : 50,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authProvider.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Login',
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

  /// Build the register link
  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Nemate račun? ',
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, base: 14),
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: _handleRegister,
          child: Text(
            'Registrujte se',
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

  /// Handle login action
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final success = await authProvider.login(username, password);
      
      if (success && mounted) {
        // Save auth data to SharedPreferences
        await AuthHelper.saveAuthData(
          token: authProvider.token!,
          userId: authProvider.userId!,
          roleId: authProvider.roleId!,
          roleName: authProvider.roleName ?? '',
          username: username,
        );
        
        NotificationHelper.showSuccess(context, 'Uspješno ste se prijavili!');
        // Navigation will be handled automatically by AuthWrapper
      } else if (mounted) {
        final errorMessage = authProvider.errorMessage ?? 'Greška prilikom prijave';
        NotificationHelper.showError(context, errorMessage);
      }
    } catch (e) {
        if (mounted) {
          NotificationHelper.showApiError(context, e);
      }
    }
  }

  /// Handle register action
  Future<void> _handleRegister() async {
    // Navigate to register screen and get the username if registration is successful
    final username = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
    
    // If registration was successful and username was returned, pre-fill it
    if (username != null && username.isNotEmpty) {
      _usernameController.text = username;
      NotificationHelper.showInfo(
        context, 
        'Možete se prijaviti sa novim korisničkim imenom.'
      );
    }
  }
}
