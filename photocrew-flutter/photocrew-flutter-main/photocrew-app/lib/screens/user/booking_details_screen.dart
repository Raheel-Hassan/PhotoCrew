// lib/screens/user/booking_details_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:photocrew/widgets/custom_back_button.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  Future<void> _cancelBooking(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Cancel Booking',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text('Are you sure you want to cancel this booking?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({'status': 'cancelled'});

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling booking: $e')),
        );
      }
    }
  }

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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return  Center(child: CircularProgressIndicator(
              color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
            ));
          }

          final booking = snapshot.data!.data() as Map<String, dynamic>?;
          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }

          final date = (booking['date'] as Timestamp).toDate();
          final photographerId = booking['photographerId'] as String;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Details',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                _PhotographerInfo(photographerId: photographerId),
                const SizedBox(height: 24),
                _DetailCard(
                  title: 'Event Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        icon: Icons.event,
                        title: 'Event Type',
                        value: booking['eventType'],
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        title: 'Date',
                        value: DateFormat('EEEE, MMMM d, yyyy').format(date),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.access_time,
                        title: 'Time',
                        value:
                            '${booking['startTime']} - ${booking['endTime']}',
                      ),
                      if (booking['notes']?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Icons.note,
                          title: 'Notes',
                          value: booking['notes'],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  title: 'Booking Status',
                  child: Column(
                    children: [
                      _BookingStatusBadge(status: booking['status']),
                      if (booking['status'] == 'pending') ...[
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for photographer confirmation',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (booking['status'] == 'confirmed' ||
                        booking['status'] == 'pending') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelBooking(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('Cancel Booking'),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final chatId = [
                            FirebaseAuth.instance.currentUser?.uid,
                            photographerId,
                          ]..sort();
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: chatId.join('_'),
                          );
                        },
                        child: const Text('Message Photographer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black54
              : Colors.white54,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotographerInfo extends StatelessWidget {
  final String photographerId;

  const _PhotographerInfo({required this.photographerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('photographers')
          .doc(photographerId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final photographer = snapshot.data?.data() as Map<String, dynamic>?;
        if (photographer == null) return const SizedBox();

        return Card(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[200]
              : Colors.grey[800],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 30,
              backgroundImage:
                  photographer['portfolioImages']?.isNotEmpty == true
                      ? NetworkImage(photographer['portfolioImages'][0])
                      : null,
              child: photographer['portfolioImages']?.isEmpty ?? true
                  ? Text(photographer['name'][0].toUpperCase())
                  : null,
            ),
            title: Text(
              photographer['name'],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              '${photographer['experience']} years of experience',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => Navigator.pushNamed(
                context,
                '/photographer/details',
                arguments: photographerId,
              ),
            ),
          ),
        );
      },
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
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending Confirmation';
        icon = Icons.pending_outlined;
        break;
      case 'confirmed':
        color = Colors.green;
        text = 'Confirmed';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
