// lib/screens/select_user_type_screen.dart
import 'package:flutter/material.dart';
import 'package:photocrew/widgets/custom_back_button.dart';

class SelectUserTypeScreen extends StatelessWidget {
  const SelectUserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: CustomBackButton(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Join PhotoBook',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Choose how you want to use PhotoBook',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              _UserTypeCard(
                title: 'Looking for a Photographer',
                description: 'Find and book professional photographers for your events',
                icon: Icons.photo_camera_outlined,
                onTap: () => Navigator.pushNamed(context, '/signup/user'),
              ),
              const SizedBox(height: 16),
              _UserTypeCard(
                title: 'I am a Photographer',
                description: 'Showcase your work and get client bookings',
                icon: Icons.camera_alt,
                onTap: () => Navigator.pushNamed(context, '/signup/photographer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}