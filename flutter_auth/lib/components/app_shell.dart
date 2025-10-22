import 'package:flutter/material.dart';
import 'package:flutter_auth/components/bottom_nav_bar.dart';
import 'package:flutter_auth/pages/home_page.dart';
import 'package:flutter_auth/pages/leaderboard_page_firebase.dart';
import 'package:flutter_auth/pages/events_page.dart';
import 'package:flutter_auth/pages/qr_scanner_page.dart';



class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // keep track of the selected tab
  int _currentIndex = 0;

  // list your pages in the same order as the nav bar items
  static const List<Widget> _tabs = [
    HomePage(),
    EventsPage(),
    LeaderboardPageFirebase(),
    QrScannerPage(),
  ];

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody if your nav bar floats over content
      extendBody: true,

      // display the currently selected page
      body: _tabs[_currentIndex],

      // your reusable nav bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}
