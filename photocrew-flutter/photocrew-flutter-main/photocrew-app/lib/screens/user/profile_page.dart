import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photocrew/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

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
            .collection('users')
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

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            return const Center(child: Text('No user data found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[300]
                            : Colors.grey[800],
                    child: Text(
                      userData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoCard(
                  context,
                  title: 'Personal Information',
                  children: [
                    _buildInfoRow(context, 'Name', userData['name'] ?? 'N/A'),
                    _buildInfoRow(context, 'Email', userData['email'] ?? 'N/A'),
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
                      label: 'Edit Name',
                      onTap: () {
                        Navigator.pushNamed(context, '/user/edit-name');
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      onTap: () {
                        Navigator.pushNamed(context, '/user/change-password');
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () {
                        Navigator.pushNamed(context, '/user/notifications');
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: () {
                        Navigator.pushNamed(context, '/user/help-support');
                      },
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
    final themeProvider = Provider.of<ThemeProvider>(context);

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
            ListTile(
              leading: Icon(themeProvider.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(
                inactiveTrackColor: Colors.grey[300],
                activeColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
              contentPadding: EdgeInsets.zero,
            ),
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
