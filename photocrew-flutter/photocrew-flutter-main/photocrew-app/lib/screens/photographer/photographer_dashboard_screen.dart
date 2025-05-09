// lib/screens/photographer/photographer_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PhotographerDashboardScreen extends StatelessWidget {
  const PhotographerDashboardScreen({super.key});

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
            _BookingStats(photographerId: currentUser?.uid ?? ''),
            const SizedBox(height: 24),
            _UpcomingBookings(photographerId: currentUser?.uid ?? ''),
            const SizedBox(height: 24),
            _RecentActivity(photographerId: currentUser?.uid ?? ''),
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
          .collection('photographers')
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
            child: Row(
              children: [
                if (userData['portfolioImages']?.isNotEmpty ?? false)
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[200]
                            : Colors.grey[900],
                    radius: 30,
                    backgroundImage:
                        NetworkImage(userData['portfolioImages'][0]),
                  )
                else
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[200]
                            : Colors.grey[900],
                    child: Text(
                      userData['name']?[0].toUpperCase() ?? 'P',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        userData['name'] ?? 'Photographer',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BookingStats extends StatelessWidget {
  final String photographerId;

  const _BookingStats({required this.photographerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('photographerId', isEqualTo: photographerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
              height: 100,
              child: Center(
                  child: CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              )));
        }

        final bookings = snapshot.data!.docs;
        final totalBookings = bookings.length;
        final pendingBookings = bookings
            .where((b) => (b.data() as Map)['status'] == 'pending')
            .length;
        final confirmedBookings = bookings
            .where((b) => (b.data() as Map)['status'] == 'confirmed')
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total',
                    value: totalBookings.toString(),
                    icon: Icons.calendar_month,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: pendingBookings.toString(),
                    icon: Icons.pending_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Confirmed',
                    value: confirmedBookings.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[200]
          : Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingBookings extends StatelessWidget {
  final String photographerId;

  const _UpcomingBookings({required this.photographerId});

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
              onPressed: () =>
                  Navigator.pushNamed(context, '/photographer/bookings'),
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
              .where('photographerId', isEqualTo: photographerId)
              .where('date', isGreaterThanOrEqualTo: Timestamp.now())
              .orderBy('date')
              .limit(3)
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

            final bookings = snapshot.data!.docs;

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
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index].data() as Map<String, dynamic>;
                final date = (booking['date'] as Timestamp).toDate();

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(booking['clientId'])
                      .get(),
                  builder: (context, clientSnapshot) {
                    final clientName =
                        clientSnapshot.data?.get('name') ?? 'Client';

                    return Card(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[200]
                          : Colors.grey[800],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/photographer/booking/details',
                          arguments: bookings[index].id,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking['eventType'],
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            _BookingStatusBadge(status: booking['status']),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black54
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 8),
                                Text(clientName),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black54
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 8),
                                Text(DateFormat('MMM d, yyyy').format(date)),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black54
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                    '${booking['startTime']} - ${booking['endTime']}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final String photographerId;

  const _RecentActivity({required this.photographerId});

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
              .where('photographerId', isEqualTo: photographerId)
              .orderBy('createdAt', descending: true)
              .limit(5)
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

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity =
                    activities[index].data() as Map<String, dynamic>;
                final date = (activity['createdAt'] as Timestamp).toDate();

                return Card(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : Colors.grey[800],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/photographer/booking/details',
                      arguments: activities[index].id,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                      child: Icon(
                        _getActivityIcon(activity['status']),
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    title: Text('New booking for ${activity['eventType']}'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(date)),
                    trailing: _BookingStatusBadge(status: activity['status']),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  IconData _getActivityIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_outlined;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.calendar_today;
    }
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
          fontSize: 12,
        ),
      ),
    );
  }
}

// TODO: MONTHLY EARNINGS CHART
// class _MonthlyEarningsChart extends StatelessWidget {
//   final String photographerId;

//   const _MonthlyEarningsChart({required this.photographerId});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('bookings')
//           .where('photographerId', isEqualTo: photographerId)
//           .where('status', isEqualTo: 'confirmed')
//           .orderBy('date', descending: true)
//           .limit(30)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return SizedBox(
//               height: 200,
//               child: Center(
//                   child: CircularProgressIndicator(
//                 color: Theme.of(context).brightness == Brightness.light
//                     ? Colors.black
//                     : Colors.white,
//               )));
//         }

//         final bookings = snapshot.data!.docs;

//         return Card(
//           color: Theme.of(context).brightness == Brightness.light
//               ? Colors.grey[200]
//               : Colors.grey[800],
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Monthly Performance',
//                   style: Theme.of(context).textTheme.titleLarge,
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildPerformanceMetric(
//                       context,
//                       'Bookings',
//                       bookings.length.toString(),
//                     ),
//                     _buildPerformanceMetric(
//                       context,
//                       'Completion Rate',
//                       '${((bookings.where((b) => (b.data() as Map)['status'] == 'confirmed').length / bookings.length) * 100).toStringAsFixed(1)}%',
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildPerformanceMetric(
//       BuildContext context, String label, String value) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//         ),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall,
//         ),
//       ],
//     );
//   }
// }
