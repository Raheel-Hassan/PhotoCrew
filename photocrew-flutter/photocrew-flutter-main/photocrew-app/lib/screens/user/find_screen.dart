// lib/screens/user/find_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFindScreen extends StatefulWidget {
  const UserFindScreen({super.key});

  @override
  State<UserFindScreen> createState() => _UserFindScreenState();
}

class _UserFindScreenState extends State<UserFindScreen> {
  final _searchController = TextEditingController();
  String _selectedSpecialty = 'All';
  final List<String> _specialties = [
    'All',
    'Wedding',
    'Portrait',
    'Event',
    'Fashion',
    'Product',
    'Architecture'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Photographer',
          style:
              Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search photographers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _specialties.length,
                    itemBuilder: (context, index) {
                      final specialty = _specialties[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          color: WidgetStatePropertyAll(
                            Theme.of(context).brightness == Brightness.light
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                          ),
                          checkmarkColor:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.white
                                  : Colors.black,
                          label: Text(
                            specialty,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          selected: _selectedSpecialty == specialty,
                          onSelected: (selected) {
                            setState(() => _selectedSpecialty = specialty);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildPhotographersQuery(),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black
                                    : Colors.white),
                        const SizedBox(height: 16),
                        Text('No photographers found',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: photographers.length,
                  itemBuilder: (context, index) {
                    final photographer =
                        photographers[index].data() as Map<String, dynamic>;
                    return _PhotographerCard(
                      photographer: photographer,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/photographer/details',
                        arguments: photographers[index].id,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildPhotographersQuery() {
    var query = FirebaseFirestore.instance
        .collection('photographers')
        .where('isApproved', isEqualTo: true);

    if (_selectedSpecialty != 'All') {
      query = query.where('specialties', arrayContains: _selectedSpecialty);
    }

    if (_searchController.text.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchController.text)
          .where('name', isLessThan: '${_searchController.text}z');
    }

    return query.snapshots();
  }
}

class _PhotographerCard extends StatelessWidget {
  final Map<String, dynamic> photographer;
  final VoidCallback onTap;

  const _PhotographerCard({
    required this.photographer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[200]
          : Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (photographer['portfolioImages']?.isNotEmpty ?? false)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  photographer['portfolioImages'][0],
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photographer['name'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    photographer['bio'],
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (photographer['specialties'] as List<dynamic>)
                        .map((specialty) => Chip(
                              label: Text(specialty),
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[200]
                                  : Colors.grey[800],
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
