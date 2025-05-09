import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecentActivitiesCard extends StatelessWidget {
  const RecentActivitiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
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

                final activities = snapshot.data?.docs ?? [];

                if (activities.isEmpty) {
                  return const Center(
                    child: Text('No recent activities'),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: activities.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final activity =
                        activities[index].data() as Map<String, dynamic>;
                    final createdAt =
                        (activity['createdAt'] as Timestamp).toDate();

                    IconData activityIcon;
                    Color iconColor;
                    String activityText;

                    switch (activity['status']) {
                      case 'pending':
                        activityIcon = Icons.pending_outlined;
                        iconColor = Colors.orange;
                        activityText = 'New booking request';
                        break;
                      case 'confirmed':
                        activityIcon = Icons.check_circle_outline;
                        iconColor = Colors.green;
                        activityText = 'Booking confirmed';
                        break;
                      case 'cancelled':
                        activityIcon = Icons.cancel_outlined;
                        iconColor = Colors.red;
                        activityText = 'Booking cancelled';
                        break;
                      default:
                        activityIcon = Icons.info_outline;
                        iconColor = Colors.grey;
                        activityText = 'Booking status updated';
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Icon(activityIcon, color: iconColor),
                      ),
                      title: Text(
                        activityText,
                        style: const TextStyle(
                          fontFamily: 'Space Mono',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['eventType'],
                            style: const TextStyle(fontFamily: 'Space Mono'),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy h:mm a').format(createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
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
