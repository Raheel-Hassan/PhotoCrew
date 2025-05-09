// lib/screens/photographer/photographer_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PhotographerBookingsScreen extends StatefulWidget {
  const PhotographerBookingsScreen({super.key});

  @override
  State<PhotographerBookingsScreen> createState() =>
      _PhotographerBookingsScreenState();
}

class _PhotographerBookingsScreenState
    extends State<PhotographerBookingsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'all';
  final _searchController = TextEditingController();
  bool _isLoading = false;

  Future<void> _refreshBookings() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor:
                  Theme.of(context).brightness == Brightness.light
                      ? Colors.black.withOpacity(0.1)
                      : Colors.white.withOpacity(0.1),
            ),
            colorScheme: Theme.of(context).brightness == Brightness.light
                ? const ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  )
                : const ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                    onSurface: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedStatus = 'all';
      _searchController.clear();
    });
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('bookings')
        .where('photographerId',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid);

    if (_startDate != null && _endDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
      query = query.where('date',
          isLessThanOrEqualTo:
              Timestamp.fromDate(_endDate!.add(const Duration(days: 1))));
    }

    if (_selectedStatus != 'all') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return query.orderBy('date', descending: false);
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $status successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookings',
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
                    hintText: 'Search by event type...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
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
                          _startDate != null && _endDate != null
                              ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                              : 'Select Dates',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        selected: _startDate != null,
                        onSelected: (_) => _selectDateRange(),
                        avatar: Icon(
                          Icons.calendar_month,
                          size: 16,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (var status in [
                        'all',
                        'pending',
                        'confirmed',
                        'cancelled'
                      ])
                        Padding(
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
                              status.capitalize(),
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            selected: _selectedStatus == status,
                            onSelected: (selected) {
                              setState(() => _selectedStatus = status);
                            },
                          ),
                        ),
                      if (_startDate != null ||
                          _selectedStatus != 'all' ||
                          _searchController.text.isNotEmpty)
                        FilterChip(
                          label: Text(
                            'Clear Filters',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          onSelected: (_) => _clearFilters(),
                          avatar: Icon(
                            Icons.clear,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshBookings,
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery().snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting ||
                      _isLoading) {
                    return Center(
                        child: CircularProgressIndicator(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ));
                  }

                  var bookings = snapshot.data?.docs ?? [];

                  if (_searchController.text.isNotEmpty) {
                    bookings = bookings.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['eventType']
                          .toString()
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase());
                    }).toList();
                  }

                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black
                                    : Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (_startDate != null ||
                              _selectedStatus != 'all' ||
                              _searchController.text.isNotEmpty)
                            TextButton(
                              onPressed: _clearFilters,
                              child: Text(
                                'Clear Filters',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking =
                          bookings[index].data() as Map<String, dynamic>;
                      final bookingId = bookings[index].id;
                      final date = (booking['date'] as Timestamp).toDate();

                      return _BookingCard(
                        booking: booking,
                        date: date,
                        onConfirm: () =>
                            _updateBookingStatus(bookingId, 'confirmed'),
                        onCancel: () =>
                            _updateBookingStatus(bookingId, 'cancelled'),
                        onChatPressed: () {
                          final chatId = [
                            FirebaseAuth.instance.currentUser?.uid,
                            booking['clientId']
                          ]..sort();
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: chatId.join('_'),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final DateTime date;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onChatPressed;

  const _BookingCard({
    required this.booking,
    required this.date,
    required this.onConfirm,
    required this.onCancel,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[200]
          : Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['eventType'],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(date),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${booking['startTime']} - ${booking['endTime']}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                _BookingStatusBadge(status: booking['status']),
              ],
            ),
            if (booking['notes']?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                'Notes:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                booking['notes'],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (booking['status'] == 'pending') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      child: const Text('Accept'),
                    ),
                  ),
                ] else if (booking['status'] == 'confirmed') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onChatPressed,
                      icon: const Icon(Icons.message),
                      label: const Text('Message Client'),
                    ),
                  ),
                ] else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onChatPressed,
                      icon: const Icon(Icons.message),
                      label: const Text('Message Client'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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
        text = 'Pending';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// TODO: Implement client information dialog 

// class _ClientInfoDialog extends StatelessWidget {
//   final String clientId;

//   const _ClientInfoDialog({required this.clientId});

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       backgroundColor: Theme.of(context).brightness == Brightness.light
//           ? Colors.grey[100]
//           : Colors.grey[900],
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Client Information',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 16),
//             StreamBuilder<DocumentSnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .doc(clientId)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return Center(
//                       child: CircularProgressIndicator(
//                     color: Theme.of(context).brightness == Brightness.light
//                         ? Colors.black
//                         : Colors.white,
//                   ));
//                 }

//                 final userData = snapshot.data!.data() as Map<String, dynamic>?;
//                 if (userData == null) {
//                   return const Text('Client information not found');
//                 }

//                 return Column(
//                   children: [
//                     ListTile(
//                       leading: const Icon(Icons.person_outline),
//                       title: const Text('Name'),
//                       subtitle: Text(userData['name'] ?? 'N/A'),
//                     ),
//                     ListTile(
//                       leading: const Icon(Icons.email_outlined),
//                       title: const Text('Email'),
//                       subtitle: Text(userData['email'] ?? 'N/A'),
//                     ),
//                     // Add more client information as needed
//                   ],
//                 );
//               },
//             ),
//             const SizedBox(height: 16),
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text(
//                 'Close',
//                 style: TextStyle(
//                   color: Theme.of(context).brightness == Brightness.light
//                       ? Colors.black
//                       : Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
