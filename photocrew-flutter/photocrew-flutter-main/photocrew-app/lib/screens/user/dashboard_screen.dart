// lib/screens/user/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          'Dashboard',
          style:
              Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WelcomeCard(currentUser: currentUser),
            const SizedBox(height: 24),
            _UpcomingBookings(
              currentUser: currentUser,
              onViewAll: () => Navigator.pushNamed(context, '/bookings/all'),
            ),
            const SizedBox(height: 24),
            _RecommendedPhotographers(),
            const SizedBox(height: 24),
            _RecentActivity(currentUser: currentUser),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final User? currentUser;

  const _WelcomeCard({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox();

        return Card(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[200]
              : Colors.grey[800],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[200]
                              : Colors.grey[800],
                      child: Text(
                        userData['name']?[0].toUpperCase() ?? 'U',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          userData['name'] ?? 'User',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UpcomingBookings extends StatelessWidget {
  final User? currentUser;
  final VoidCallback onViewAll;

  const _UpcomingBookings({
    required this.currentUser,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Bookings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('clientId', isEqualTo: currentUser?.uid)
              .where('date', isGreaterThanOrEqualTo: Timestamp.now())
              .orderBy('date')
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white);
            }

            final bookings = snapshot.data?.docs ?? [];

            if (bookings.isEmpty) {
              return Card(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[200]
                    : Colors.grey[800],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 48,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No upcoming bookings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Book a photographer for your next event',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: bookings.map((booking) {
                final data = booking.data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp).toDate();

                return Card(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[200]
                      : Colors.grey[800],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/booking/details',
                      arguments: booking.id,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      data['eventType'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(DateFormat('MMM d, yyyy').format(date)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 8),
                            Text('${data['startTime']} - ${data['endTime']}'),
                          ],
                        ),
                      ],
                    ),
                    trailing: _BookingStatusBadge(status: data['status']),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RecommendedPhotographers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Photographers',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('photographers')
                .where('isApproved', isEqualTo: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white));
              }

              final photographers = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photographers.length,
                itemBuilder: (context, index) {
                  final photographer =
                      photographers[index].data() as Map<String, dynamic>;
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    child: Card(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[200]
                          : Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/photographer/details',
                          arguments: photographers[index].id,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (photographer['portfolioImages']?.isNotEmpty ??
                                false)
                              Image.network(
                                photographer['portfolioImages'][0],
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            else
                              Container(
                                height: 120,
                                color: Colors.grey,
                                child: const Icon(Icons.camera_alt),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    photographer['name'],
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${photographer['experience']} years exp.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final User? currentUser;

  const _RecentActivity({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('clientId', isEqualTo: currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white));
            }

            final activities = snapshot.data!.docs;

            if (activities.isEmpty) {
              return Card(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[200]
                    : Colors.grey[800],
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recent activity'),
                ),
              );
            }

            return Column(
              children: activities.map((activity) {
                final data = activity.data() as Map<String, dynamic>;
                final date = (data['createdAt'] as Timestamp).toDate();

                return Card(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[200]
                      : Colors.grey[800],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/booking/details',
                      arguments: activity.id,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[300]
                              : Colors.grey[800],
                      child: Icon(
                        Icons.calendar_month,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                    title: Text('Booking for ${data['eventType']}'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(date)),
                    trailing: _BookingStatusBadge(status: data['status']),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  final String status;

  const _BookingStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'confirmed':
        color = Colors.green;
        text = 'Confirmed';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
