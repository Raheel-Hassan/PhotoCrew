// lib/screens/photographer/photographer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:photocrew/screens/photographer/photographer_bookings_screen.dart';
import 'package:photocrew/screens/photographer/photographer_dashboard_screen.dart';
import 'package:photocrew/screens/photographer/photographer_messages_screen.dart.dart';
import 'package:photocrew/screens/photographer/photographer_profile_screen.dart';

class PhotographerHomeScreen extends StatefulWidget {
  const PhotographerHomeScreen({super.key});

  @override
  State<PhotographerHomeScreen> createState() => _PhotographerHomeScreenState();
}

class _PhotographerHomeScreenState extends State<PhotographerHomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    PhotographerDashboardScreen(),
    PhotographerBookingsScreen(),
    PhotographerMessagesScreen(),
    PhotographerProfileScreen(),
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
        indicatorColor: isDarkMode ? Colors.white : Colors.black,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
              color: _currentIndex == 0
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
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
              Icons.calendar_month_outlined,
              color: _currentIndex == 1
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            selectedIcon: Icon(
              Icons.calendar_month,
              color: _currentIndex == 1
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            label: 'Bookings',
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
