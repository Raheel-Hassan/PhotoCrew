// lib/screens/photographer/photographer_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photocrew/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class PhotographerProfileScreen extends StatelessWidget {
  const PhotographerProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          'Profile',
          style:
              Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('photographers')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
            ));
          }

          final photographerData =
              snapshot.data!.data() as Map<String, dynamic>?;
          if (photographerData == null) {
            return const Center(child: Text('No photographer data found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      if (photographerData['portfolioImages']?.isNotEmpty ??
                          false)
                        CircleAvatar(
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.grey[200]
                                  : Colors.grey[800],
                          radius: 50,
                          backgroundImage: NetworkImage(
                            photographerData['portfolioImages'][0],
                          ),
                        )
                      else
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.grey[300]
                                  : Colors.grey[800],
                          child: Text(
                            photographerData['name']
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                'P',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoCard(
                  context,
                  title: 'Personal Information',
                  children: [
                    _buildInfoRow(
                        context, 'Name', photographerData['name'] ?? 'N/A'),
                    _buildInfoRow(
                        context, 'Email', photographerData['email'] ?? 'N/A'),
                    _buildInfoRow(
                      context,
                      'Experience',
                      '${photographerData['experience']} years',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  title: 'Specialties',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (photographerData['specialties'] as List<dynamic>)
                              .map((specialty) => Chip(
                                    label: Text(specialty),
                                    backgroundColor:
                                        Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Colors.grey[200]
                                            : Colors.grey[800],
                                  ))
                              .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  context,
                  title: 'App Settings',
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.person_outline,
                      label: 'Edit Profile',
                      onTap: () {
                        Navigator.pushNamed(
                            context, '/photographer/edit-profile');
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      onTap: () {
                        Navigator.pushNamed(
                            context, '/photographer/change-password');
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () {
                        Navigator.pushNamed(
                            context, '/photographer/notifications');
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: () {
                        Navigator.pushNamed(
                            context, '/photographer/help-support');
                      },
                    ),
                    const SizedBox(height: 8),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => ListTile(
                        leading: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                        title: const Text('Dark Mode'),
                        trailing: Switch(
                          inactiveTrackColor: Colors.grey[300],
                          activeColor:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                          value: themeProvider.isDarkMode,
                          onChanged: (_) => themeProvider.toggleTheme(),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[200]
            : Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[200]
          : Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
