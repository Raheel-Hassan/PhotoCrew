import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhotographerVerificationCard extends StatelessWidget {
  const PhotographerVerificationCard({super.key});

  Future<void> _updatePhotographerStatus(
      String photographerId, bool isApproved) async {
    await FirebaseFirestore.instance
        .collection('photographers')
        .doc(photographerId)
        .update({'isApproved': isApproved});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Verifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('photographers')
                  .where('isApproved', isEqualTo: false)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                  ));
                }

                final photographers = snapshot.data?.docs ?? [];

                if (photographers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No pending verifications'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: photographers.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final photographer =
                        photographers[index].data() as Map<String, dynamic>;
                    final photographerId = photographers[index].id;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          photographer['name'][0].toUpperCase(),
                          style: const TextStyle(fontFamily: 'Space Mono'),
                        ),
                      ),
                      title: Text(
                        photographer['name'],
                        style: const TextStyle(
                          fontFamily: 'Space Mono',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${photographer['experience']} years experience',
                        style: const TextStyle(fontFamily: 'Space Mono'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    _PhotographerDetailsDialog(
                                  photographer: photographer,
                                ),
                              );
                            },
                            child: Text(
                              'View Details',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            color: Colors.green,
                            onPressed: () => _updatePhotographerStatus(
                              photographerId,
                              true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined),
                            color: Colors.red,
                            onPressed: () => _updatePhotographerStatus(
                              photographerId,
                              false,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotographerDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> photographer;

  const _PhotographerDetailsDialog({
    required this.photographer,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Colors.grey[900],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Photographer Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(label: 'Name', value: photographer['name']),
              _DetailRow(label: 'Email', value: photographer['email']),
              _DetailRow(
                label: 'Experience',
                value: '${photographer['experience']} years',
              ),
              _DetailRow(label: 'Equipment', value: photographer['equipment']),
              _DetailRow(label: 'Bio', value: photographer['bio']),
              const SizedBox(height: 16),
              Text(
                'Specialties',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (photographer['specialties'] as List<dynamic>)
                    .map((specialty) => Chip(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[200]
                                : Colors.grey[800],
                        label: Text(specialty)))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Space Mono',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Space Mono'),
            ),
          ),
        ],
      ),
    );
  }
}
