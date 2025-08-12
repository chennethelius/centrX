// lib/widgets/calendar_widget.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/calendar_service.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({Key? key}) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  final CalendarService _service = CalendarService();
  Map<DateTime, List<Map<String, dynamic>>> _eventsByDate = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  StreamSubscription<Map<DateTime, List<Map<String, dynamic>>>>? _sub;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _sub = _service.userEventsByDateStream().listen((map) {
        if (!mounted) return;
        setState(() {
          _eventsByDate = map;
          // if selected day becomes null or not in map, keep selection if possible
          if (_selectedDay == null) {
            _selectedDay = _focusedDay;
          }
        });
      }, onError: (err) {
        debugPrint('CalendarService error: $err');
      });
    } else {
      debugPrint('No user signed in - calendar inactive.');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<DateTime> get _rsvpDays => _eventsByDate.keys.toList();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;

      // Outer container styling (keeps your look & feel)
      final content = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(30),
              Colors.white.withAlpha(10),
            ],
          ),
          border: Border.all(
            color: Colors.white.withAlpha(80),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
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
              padding: const EdgeInsets.all(20),
              child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
            ),
          ),
        ),
      );

      return content;
    });
  }

  // Wide: calendar on left, schedule on right
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left column: calendar
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildCalendarGrid(),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Right column: schedule for selected day
        Expanded(
          flex: 1,
          child: _buildEventSchedule(),
        )
      ],
    );
  }

  // Narrow: calendar above, schedule below
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildCalendarGrid(),
        const SizedBox(height: 12),
        SizedBox(
          height: 220, // limit height so page doesn't get extremely long
          child: _buildEventSchedule(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(IconlyBold.calendar, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Text('Your Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const Spacer(),
        _navButton(
          icon: IconlyLight.arrow_left_2,
          onTap: () => setState(() {
            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
          }),
        ),
        const SizedBox(width: 8),
        Text(
          _getMonthYear(_focusedDay),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(width: 8),
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
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday; // 1 = Mon
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Row(
          children: weekdays
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(6, (week) {
          return Row(
            children: List.generate(7, (dow) {
              final dayNum = week * 7 + dow - firstWeekday + 2;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }

              final thisDay = DateTime(_focusedDay.year, _focusedDay.month, dayNum);
              final isSelected = _selectedDay != null && _isSameDay(_selectedDay!, thisDay);
              final isToday = _isSameDay(DateTime.now(), thisDay);
              final normalized = DateTime(thisDay.year, thisDay.month, thisDay.day);
              final hasEvent = _eventsByDate.containsKey(normalized);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = thisDay),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withAlpha(80) : isToday ? Colors.white.withAlpha(30) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? Border.all(color: Colors.white.withAlpha(160), width: 1.5) : null,
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
                            top: 6,
                            right: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF06B6D4),
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(width: 8, height: 8),
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

  Widget _buildEventSchedule() {
    final selected = _selectedDay ?? DateTime.now();
    final key = DateTime(selected.year, selected.month, selected.day);
    final events = _eventsByDate[key] ?? [];

    if (events.isEmpty) {
      return Center(
        child: Text(
          'No events on ${selected.month}/${selected.day}/${selected.year}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    // Color palette for multiple events
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red];

    // Sort by start time if available
    events.sort((a, b) {
      final sa = a['startTime'] as DateTime?;
      final sb = b['startTime'] as DateTime?;
      if (sa == null || sb == null) return 0;
      return sa.compareTo(sb);
    });

    return ListView.builder(
      itemCount: events.length,
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, i) {
        final e = events[i];
        final start = e['startTime'] as DateTime?;
        final end = e['endTime'] as DateTime?;
        final color = colors[i % colors.length];

        final timeText = (start != null && end != null)
            ? '${_fmtTime(start)} - ${_fmtTime(end)}'
            : (start != null ? _fmtTime(start) : 'Time TBA');

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: ListTile(
            title: Text(e['title'] ?? 'Event', style: const TextStyle(color: Colors.white)),
            subtitle: Text(timeText, style: const TextStyle(color: Colors.white70)),
            trailing: Text(e['location'] ?? '', style: const TextStyle(color: Colors.white70)),
            onTap: () {
              // optional: navigate to event detail
            },
          ),
        );
      },
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _getMonthYear(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}
