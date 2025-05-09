// lib/screens/user/photographer_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:photocrew/widgets/custom_back_button.dart';

class PhotographerDetailsScreen extends StatelessWidget {
  final String photographerId;

  const PhotographerDetailsScreen({
    super.key,
    required this.photographerId,
  });

  Future<void> _startChat(BuildContext context, String photographerId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final participants = [currentUser.uid, photographerId]..sort();
    final chatId = participants.join('_');

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUser.uid, photographerId],
      'lastMessage': null,
      'lastMessageTime': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    Navigator.pushNamed(context, '/chat', arguments: chatId);
  }

  Future<void> _initiateBooking(
      BuildContext context, Map<String, dynamic> photographer) async {
    await Navigator.pushNamed(
      context,
      '/booking/create',
      arguments: {
        'photographerId': photographerId,
        'photographerName': photographer['name'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: CustomBackButton(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('photographers')
            .doc(photographerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.white,
            ));
          }

          final photographer = snapshot.data?.data() as Map<String, dynamic>?;
          if (photographer == null) {
            return const Center(child: Text('Photographer not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (photographer['portfolioImages']?.isNotEmpty ?? false)
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: photographer['portfolioImages'].length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          photographer['portfolioImages'][index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photographer['name'],
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${photographer['experience']} years of experience',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        photographer['bio'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Equipment',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        photographer['equipment'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Specialties',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (photographer['specialties'] as List<dynamic>)
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
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _startChat(context, photographerId),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(
                                'Message',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _initiateBooking(context, photographer),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Book Now'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
