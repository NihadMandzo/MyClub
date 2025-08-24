import 'package:flutter/material.dart';
import 'package:myclub_desktop/screens/matches_screen.dart';
import 'package:myclub_desktop/screens/membership_screen.dart';
import 'package:myclub_desktop/screens/news_screen.dart';
import 'package:myclub_desktop/screens/orders_screen.dart';
import 'package:myclub_desktop/screens/players_screen.dart';
import 'package:myclub_desktop/screens/settings_screen.dart';
import 'package:myclub_desktop/screens/shop_screen.dart';
import 'package:myclub_desktop/screens/tickets_screen.dart';
import 'package:myclub_desktop/screens/user_memberships_screen.dart';
import 'navbar_layout.dart';
import 'dashboard_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int currentIndex = 0;
  String currentTitle = 'Dashboard';

  final List<Widget> screens = [
    const DashboardScreen(),
    const OrdersScreen(),
    const ShopScreen(),
    const NewsScreen(),
    const TicketsScreen(),
    const MembershipScreen(),
  const UserMembershipsScreen(),
    const PlayersScreen(),
    const MatchesScreen(),
    const SettingsScreen()
  ];
  
  final List<String> titles = [
  'Analitika',
  'Narudžbe',
  'Fan Shop',
  'Vijesti',
  'Ulaznice',
  'Članstvo',
  'Korisnička članstva',
  'Igrači',
  'Utakmice',
  'Postavke',
  ];

  @override
  Widget build(BuildContext context) {
    return NavbarLayout(
      currentIndex: currentIndex,
      title: titles[currentIndex],
      child: screens[currentIndex],
      onNavSelected: (index) {
        setState(() {
          currentIndex = index;
          currentTitle = titles[index];
        });
      },
    );
  }
}
