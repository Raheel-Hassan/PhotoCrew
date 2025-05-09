import 'package:flutter/material.dart';
import 'package:photocrew/screens/user/dashboard_screen.dart';
import 'package:photocrew/screens/user/find_screen.dart';
import 'package:photocrew/screens/user/message_screen.dart';
import 'package:photocrew/screens/user/profile_page.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    UserDashboardScreen(),
    UserFindScreen(),
    MessageScreen(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Detect current brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        indicatorColor:
            isDarkMode ? Colors.white : Colors.black, // Indicator color
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
              color: _currentIndex == 0
                  ? (isDarkMode ? Colors.black : Colors.white) // Selected icon
                  : (isDarkMode
                      ? Colors.white
                      : Colors.black), // Unselected icon
            ),
            selectedIcon: Icon(
              Icons.dashboard,
              color: _currentIndex == 0
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.search_outlined,
              color: _currentIndex == 1
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            selectedIcon: Icon(
              Icons.search,
              color: _currentIndex == 1
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            label: 'Find',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.message_outlined,
              color: _currentIndex == 2
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            selectedIcon: Icon(
              Icons.message,
              color: _currentIndex == 2
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: _currentIndex == 3
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            selectedIcon: Icon(
              Icons.person,
              color: _currentIndex == 3
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
