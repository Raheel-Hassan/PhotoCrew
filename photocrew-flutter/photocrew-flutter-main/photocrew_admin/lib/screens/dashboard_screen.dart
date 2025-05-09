import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:photocrew_admin/provider/theme_provider.dart';
import 'package:photocrew_admin/widgets/photograhper_verification_card.dart';
import 'package:photocrew_admin/widgets/photographers_list_card.dart';
import 'package:photocrew_admin/widgets/users_list_card.dart';
import 'package:provider/provider.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final themeProvider = Provider.of<ThemeProvider>(context);

    Widget buildStatsSection(
        int approvedPhotographers, int pendingPhotographers, int userCount) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      if (isMobile) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              StatCard(
                title: 'Active Photographers',
                value: approvedPhotographers.toString(),
                icon: Icons.camera_alt,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              StatCard(
                title: 'Pending Photographers',
                value: pendingPhotographers.toString(),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              StatCard(
                title: 'Total Users',
                value: userCount.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ],
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'Active Photographers',
              value: approvedPhotographers.toString(),
              icon: Icons.camera_alt,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              title: 'Pending Photographers',
              value: pendingPhotographers.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              title: 'Total Users',
              value: userCount.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.camera,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            if (!isMobile)
              Text(
                'PhotoCrew Admin',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[100]
                  : Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[100]
                  : Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('photographers')
                    .snapshots(),
                builder: (context, photographerSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      final totalPhotographers =
                          photographerSnapshot.data?.docs.length ?? 0;
                      final approvedPhotographers = photographerSnapshot
                              .data?.docs
                              .where((doc) =>
                                  (doc.data()
                                      as Map<String, dynamic>)['isApproved'] ==
                                  true)
                              .length ??
                          0;
                      final pendingPhotographers =
                          totalPhotographers - approvedPhotographers;
                      final userCount = userSnapshot.data?.docs.length ?? 0;

                      return buildStatsSection(
                        approvedPhotographers,
                        pendingPhotographers,
                        userCount,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Pending Verifications',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 24),
              const PhotographerVerificationCard(),
              const SizedBox(height: 32),
              Text(
                'Active Photographers',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Make it scroll horizontally
                child: SizedBox(
                  width: isMobile
                      ? 800
                      : screenWidth, // Fixed minimum width on mobile
                  child: const PhotographersListCard(),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Users',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: isMobile
                      ? 800
                      : screenWidth, // Fixed minimum width on mobile
                  child: const UsersListCard(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
