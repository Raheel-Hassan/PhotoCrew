// lib/screens/user/bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:photocrew/widgets/custom_back_button.dart';

class AllBookingsScreen extends StatefulWidget {
  const AllBookingsScreen({super.key});

  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'all';
  final _searchController = TextEditingController();
  bool _isLoading = false;

  Future<void> _refreshBookings() async {
    setState(() => _isLoading = true);
    // Add artificial delay to show refresh indicator
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
                        ? Colors.white
                        : Colors.black,
                rangePickerBackgroundColor:
                    Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.black),
            colorScheme: Theme.of(context).brightness == Brightness.light
                ? ColorScheme.light(
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  )
                : ColorScheme.dark(
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Colors.black,
                    onSurface: Colors.white,
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context)
                    .primaryColor, // OK/Cancel button text color
              ),
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
        .where('clientId', isEqualTo: FirebaseAuth.instance.currentUser?.uid);

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

    return query.orderBy('date', descending: true);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Bookings',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                // Search Bar
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
                // Filter Section
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Date Range Filter
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
                      // Status Filters
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
                      // Clear Filters
                      if (_startDate != null ||
                          _selectedStatus != 'all' ||
                          _searchController.text.isNotEmpty)
                        FilterChip(
                          label: Text('Clear Filters',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor)),
                          onSelected: (_) => _clearFilters(),
                          avatar: const Icon(Icons.clear, size: 16),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bookings List
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
                    return  Center(child: CircularProgressIndicator(
                      color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                    ));
                  }

                  var bookings = snapshot.data?.docs ?? [];

                  // Apply search filter
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
                              child: Text('Clear Filters',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor)),
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
                      final date = (booking['date'] as Timestamp).toDate();

                      return Card(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.grey[200]
                                  : Colors.grey[800],
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/booking/details',
                              arguments: bookings[index].id,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          booking['eventType'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      _BookingStatusBadge(
                                          status: booking['status']),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
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
                                      Text(
                                        DateFormat('MMM d, yyyy').format(date),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
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
                                        '${booking['startTime']} - ${booking['endTime']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ));
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
