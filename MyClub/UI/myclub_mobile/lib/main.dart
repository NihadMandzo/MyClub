import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/membership_provider.dart';
import 'providers/news_provider.dart';
import 'providers/user_provider.dart';
import 'providers/base_provider.dart';
import 'screens/login_screen.dart';
import 'screens/app_layout.dart';

void main() {
  runApp(const MyClubApp());
}

/// Main application widget that sets up the MaterialApp and providers
class MyClubApp extends StatelessWidget {
  const MyClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MembershipProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Set global auth provider for all BaseProvider instances
          BaseProvider.setGlobalAuthProvider(authProvider);
          
          return MaterialApp(
            title: 'MyClub Mobile',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF131A9E)),
              useMaterial3: true,
            ),
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Wrapper widget that handles authentication state and navigation
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// Check if user has a stored token and validate authentication
  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    final storedUserId = prefs.getInt('user_id');
    final storedRoleId = prefs.getInt('role_id');
    final storedRoleName = prefs.getString('role_name');
    final storedUsername = prefs.getString('username');

    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // If we have stored auth data, restore it
      if (storedToken != null && storedUserId != null && storedRoleId != null) {
        authProvider.token = storedToken;
        authProvider.userId = storedUserId;
        authProvider.roleId = storedRoleId;
        authProvider.roleName = storedRoleName;
        authProvider.username = storedUsername;
      }

      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // If user is authenticated and authorized (admin), show main app
        if (authProvider.isAuthorized) {
          return const AppLayout();
        }
        // Otherwise, show login screen
        return const LoginScreen();
      },
    );
  }
}