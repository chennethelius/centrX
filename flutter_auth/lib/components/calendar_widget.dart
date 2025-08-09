import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/calendar_service.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({Key? key}) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  final CalendarService _service = CalendarService();
  List<DateTime> _rsvpDays = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  StreamSubscription<List<DateTime>>? _subscription;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Only start listening if authenticated
      _subscription = _service.rsvpDatesStream().listen((dates) {
        if (mounted) {
          setState(() {
            _rsvpDays = dates;
          });
        }
      }, onError: (err) {
        debugPrint('Calendar stream error: $err');
      });
    } else {
      debugPrint('CalendarWidget: No user logged in, skipping stream.');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(51),
            Colors.white.withAlpha(25),
          ],
        ),
        border: Border.all(
          color: Colors.white.withAlpha(77),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        IconlyBold.calendar,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Your Events',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildCalendar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        _buildCalendarHeader(),
        const SizedBox(height: 16),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navButton(
          icon: IconlyLight.arrow_left_2,
          onTap: () => setState(() {
            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
          }),
        ),
        Text(
          _getMonthYear(_focusedDay),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        _navButton(
          icon: IconlyLight.arrow_right_2,
          onTap: () => setState(() {
            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
          }),
        ),
      ],
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Row(
          children: weekdays
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        ...List.generate(6, (week) {
          return Row(
            children: List.generate(7, (dow) {
              final dayNum = week * 7 + dow - firstWeekday + 2;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }

              final thisDay = DateTime(_focusedDay.year, _focusedDay.month, dayNum);
              final isSelected = _selectedDay != null && _isSameDay(_selectedDay!, thisDay);
              final isToday = _isSameDay(DateTime.now(), thisDay);
              final hasEvent = _rsvpDays.any((d) => _isSameDay(d, thisDay));

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = thisDay),
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha(77)
                          : isToday
                              ? Colors.white.withAlpha(26)
                              : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withAlpha(153),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            dayNum.toString(),
                            style: TextStyle(
                              color: (isSelected || isToday) ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (hasEvent)
                          const Positioned(
                            top: 4,
                            right: 4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF06B6D4),
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(width: 6, height: 6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  String _getMonthYear(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
