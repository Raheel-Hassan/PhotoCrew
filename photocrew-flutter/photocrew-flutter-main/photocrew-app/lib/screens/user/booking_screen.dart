// lib/screens/user/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:photocrew/widgets/custom_back_button.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> photographerData;

  const BookingScreen({
    super.key,
    required this.photographerData,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _eventTypeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createBooking() async {
    if (_startTime == null ||
        _endTime == null ||
        _eventTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final bookingDateTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
      );

      final bookingRef =
          await FirebaseFirestore.instance.collection('bookings').add({
        'photographerId': widget.photographerData['photographerId'],
        'clientId': currentUser.uid,
        'eventType': _eventTypeController.text,
        'date': Timestamp.fromDate(bookingDateTime),
        'startTime': '${_startTime!.hour}:${_startTime!.minute}',
        'endTime': '${_endTime!.hour}:${_endTime!.minute}',
        'notes': _notesController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create chat if it doesn't exist
      final chatId = ([
        currentUser.uid,
        widget.photographerData['photographerId']
      ]..sort())
          .join('_');

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [
          currentUser.uid,
          widget.photographerData['photographerId']
        ],
        'lastMessage': 'New booking request',
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/booking/confirmation',
        arguments: bookingRef.id,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: CustomBackButton(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book Photographer',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.photographerData['photographerName']}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            Card(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      cursorColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                      controller: _eventTypeController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        labelText: 'Event Type',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        hintText: 'e.g., Wedding, Portrait, Event',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _startTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        backgroundColor: Colors.white,
                                        dayPeriodColor: Colors.black,
                                        dayPeriodTextColor:
                                            WidgetStateColor.resolveWith(
                                                (states) {
                                          if (states
                                              .contains(WidgetState.selected)) {
                                            return Colors.white;
                                          }
                                          return Colors.black;
                                        }),
                                        hourMinuteColor: Colors.black,
                                        hourMinuteTextColor: Colors.white,
                                      ),
                                      colorScheme: const ColorScheme.light(
                                        surface: Colors.white,
                                        primary: Colors.black,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (time != null) {
                                setState(() => _startTime = time);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Time',
                                labelStyle:
                                    Theme.of(context).textTheme.bodyMedium,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_startTime?.format(context) ?? 'Select'),
                                  const Icon(Icons.access_time),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _endTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        backgroundColor: Colors.white,
                                        dayPeriodColor: Colors.black,
                                        dayPeriodTextColor:
                                            WidgetStateColor.resolveWith(
                                                (states) {
                                          if (states
                                              .contains(WidgetState.selected)) {
                                            return Colors.white;
                                          }
                                          return Colors.black;
                                        }),
                                        hourMinuteColor: Colors.black,
                                        hourMinuteTextColor: Colors.white,
                                      ),
                                      colorScheme: const ColorScheme.light(
                                        surface: Colors.white,
                                        primary: Colors.black,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() => _endTime = time);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Time',
                                labelStyle:
                                    Theme.of(context).textTheme.bodyMedium,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_endTime?.format(context) ?? 'Select'),
                                  const Icon(Icons.access_time),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      cursorColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        labelText: 'Additional Notes',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        hintText: 'Any special requirements or details',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createBooking,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                        ))
                    : const Text('Send Booking Request'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The photographer will review and confirm your booking request',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
