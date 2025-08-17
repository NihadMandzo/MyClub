import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/membership_provider.dart';
import 'providers/news_provider.dart';
import 'providers/user_provider.dart';
import 'providers/match_provider.dart';
import 'providers/base_provider.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/color_provider.dart';
import 'providers/size_provider.dart';
import 'providers/player_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/user_membership_card_provider.dart';
import 'providers/order_provider.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/app_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set system UI colors before the app runs
  runApp(const MyClubApp());
}

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
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ColorProvider()),
        ChangeNotifierProvider(create: (_) => SizeProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => UserMembershipCardProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Set global auth provider
          BaseProvider.setGlobalAuthProvider(authProvider);

          // Unauthorized handler
          BaseProvider.setGlobalUnauthorizedHandler(() async {
            print("Global unauthorized handler triggered - logging out user");
            await authProvider.logout();
          });

          return MaterialApp(
            title: 'MyClub Mobile',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue.shade700,
                primary: Colors.blue.shade700,
              ),
              scaffoldBackgroundColor: Colors.white,
            ),
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
            builder: (context, child) {
              // Apply SafeArea to every screen
              final safeChild = SafeArea(
                top: false,
                child: child ?? const SizedBox.shrink(),
              );

              // Apply system UI colors after first frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    systemNavigationBarColor: const Color(0xFF1976D2),
                    systemNavigationBarIconBrightness:
                        Brightness.light, // white nav icons
                    systemNavigationBarDividerColor:
                        const Color(0xFF1976D2), // removes fade effect
                  ),
                );
              });

              return safeChild;
            },
          );
        },
      ),
    );
  }
}

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

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    final storedUserId = prefs.getInt('user_id');
    final storedRoleId = prefs.getInt('role_id');
    final storedRoleName = prefs.getString('role_name');
    final storedUsername = prefs.getString('username');

    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (storedToken != null && storedUserId != null && storedRoleId != null) {
        authProvider.token = storedToken;
        authProvider.userId = storedUserId;
        authProvider.roleId = storedRoleId;
        authProvider.roleName = storedRoleName;
        authProvider.username = storedUsername;
      }
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return authProvider.isAuthorized
            ? const AppLayout()
            : const LoginScreen();
      },
    );
  }
}
