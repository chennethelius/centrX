// lib/widgets/calendar_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/calendar_service.dart';
import '../theme/theme_extensions.dart';

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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      final base = constraints.maxWidth / 20;

      final content = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(base * 1.4),
          color: context.secondaryLight, // 30% - Secondary neutral for cards
          border: Border.all(
            color: context.neutralGray,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: base * 1.25,
              offset: Offset(0, base * 0.6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(base),
          child: isWide ? _buildWideLayout(base) : _buildNarrowLayout(base),
        ),
      );

      return content;
    });
  }

  // Wide: calendar on left, schedule on right
  Widget _buildWideLayout(double base) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildHeader(base),
              SizedBox(height: base * 0.8),
              _buildCalendarGrid(base),
            ],
          ),
        ),
        SizedBox(width: base * 0.8),
        Expanded(
          flex: 1,
          child: _buildEventSchedule(base),
        )
      ],
    );
  }

  // Narrow: calendar above, schedule below
  Widget _buildNarrowLayout(double base) {
    final selected = _selectedDay ?? DateTime.now();
    final key = DateTime(selected.year, selected.month, selected.day);
    final events = _eventsByDate[key] ?? [];
    final hasEvents = events.isNotEmpty;
    
    return Column(
      children: [
        _buildHeader(base),
        SizedBox(height: base * 0.6),
        _buildCalendarGrid(base),
        SizedBox(height: base * 0.6),
        SizedBox(
          // Reduce height when no events
          height: hasEvents ? base * 11 : base * 3,
          child: _buildEventSchedule(base),
        ),
      ],
    );
  }

  Widget _buildHeader(double base) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _navButton(
          icon: IconlyLight.arrow_left_2,
          onTap: () => setState(() {
            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
          }),
          base: base,
        ),
        SizedBox(width: base * 0.6),
        Text(
          _getMonthYear(_focusedDay),
          style: TextStyle(fontSize: base * 0.9, fontWeight: FontWeight.w700, color: context.neutralBlack),
        ),
        SizedBox(width: base * 0.6),
        _navButton(
          icon: IconlyLight.arrow_right_2,
          onTap: () => setState(() {
            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
          }),
          base: base,
        ),
      ],
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap, required double base}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(base * 0.4),
        decoration: BoxDecoration(
          color: context.neutralGray,
          borderRadius: BorderRadius.circular(base * 0.6),
        ),
        child: Icon(icon, color: context.neutralDark, size: base * 0.9),
      ),
    );
  }

  Widget _buildCalendarGrid(double base) {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday; // 1 = Mon, 7 = Sun
    final prevMonth = DateTime(_focusedDay.year, _focusedDay.month - 1, 0);
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // Calculate how many rows we need
    // Convert weekday (1=Mon, 7=Sun) to Sun-Sat format (0=Sun, 1=Mon, ..., 6=Sat)
    final daysFromPrevMonth = firstWeekday % 7; // Sunday (7) becomes 0, Monday (1) becomes 1, etc.
    final totalCells = daysFromPrevMonth + daysInMonth;
    final rowsNeeded = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          children: weekdays
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(color: context.neutralMedium, fontWeight: FontWeight.w500, fontSize: base * 0.6),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: base * 0.4),
        ...List.generate(rowsNeeded, (week) {
          return Row(
            children: List.generate(7, (dow) {
              final cellIndex = week * 7 + dow;
              
              DateTime thisDay;
              bool isCurrentMonth;
              int displayDay;
              
              if (cellIndex < daysFromPrevMonth) {
                // Previous month days (only at the beginning)
                displayDay = prevMonth.day - (daysFromPrevMonth - cellIndex - 1);
                thisDay = DateTime(prevMonth.year, prevMonth.month, displayDay);
                isCurrentMonth = false;
              } else if (cellIndex < daysFromPrevMonth + daysInMonth) {
                // Current month days
                displayDay = cellIndex - daysFromPrevMonth + 1;
                thisDay = DateTime(_focusedDay.year, _focusedDay.month, displayDay);
                isCurrentMonth = true;
              } else {
                // Next month days (fill remaining cells)
                displayDay = cellIndex - daysFromPrevMonth - daysInMonth + 1;
                thisDay = DateTime(_focusedDay.year, _focusedDay.month + 1, displayDay);
                isCurrentMonth = false;
              }

              final isSelected = _selectedDay != null && _isSameDay(_selectedDay!, thisDay);
              final isToday = _isSameDay(DateTime.now(), thisDay);
              final normalized = DateTime(thisDay.year, thisDay.month, thisDay.day);
              final hasEvent = _eventsByDate.containsKey(normalized);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = thisDay),
                  child: Container(
                    height: base * 2.2,
                    margin: EdgeInsets.all(base * 0.15),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? context.accentNavy.withValues(alpha: 0.2)
                          : isToday 
                              ? context.accentNavyLight.withValues(alpha: 0.1)
                              : null,
                      borderRadius: BorderRadius.circular(base * 0.5),
                      border: isSelected 
                          ? Border.all(color: context.accentNavy, width: base * 0.08) 
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            displayDay.toString(),
                            style: TextStyle(
                              color: !isCurrentMonth 
                                  ? context.neutralMedium  // Gray out other month dates
                                  : (isSelected || isToday) 
                                      ? context.accentNavy 
                                      : context.neutralDark,
                              fontWeight: FontWeight.w600,
                              fontSize: base * 0.8,
                            ),
                          ),
                        ),
                        if (hasEvent && isCurrentMonth)
                          Positioned(
                            top: base * 0.27,
                            right: base * 0.27,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: context.accentNavy,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(width: base * 0.36, height: base * 0.36),
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

  Widget _buildEventSchedule(double base) {
    final selected = _selectedDay ?? DateTime.now();
    final key = DateTime(selected.year, selected.month, selected.day);
    final events = _eventsByDate[key] ?? [];

    if (events.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: base * 0.8),
        child: Center(
          child: Text(
            'No events on ${selected.month}/${selected.day}/${selected.year}',
            style: TextStyle(
              color: context.neutralMedium, 
              fontSize: base * 0.7,
            ),
          ),
        ),
      );
    }

    // Color palette for multiple events - using our new color system
    final colors = [
      context.accentNavy, 
      context.successGreen, 
      context.infoBlue, 
      context.warningOrange, 
      context.errorRed
    ];

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
      padding: EdgeInsets.only(top: base * 0.4),
      itemBuilder: (context, i) {
        final e = events[i];
        final start = e['startTime'] as DateTime?;
        final end = e['endTime'] as DateTime?;
        final color = colors[i % colors.length];

        final timeText = (start != null && end != null)
            ? '${_fmtTime(start)} - ${_fmtTime(end)}'
            : (start != null ? _fmtTime(start) : 'Time TBA');

        return Container(
          margin: EdgeInsets.symmetric(vertical: base * 0.27),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(base * 0.5),
            border: Border(left: BorderSide(color: color, width: base * 0.2)),
          ),
          child: ListTile(
            title: Text(e['title'] ?? 'Event', style: TextStyle(color: context.neutralBlack, fontSize: base * 0.8)),
            subtitle: Text(timeText, style: TextStyle(color: context.neutralDark, fontSize: base * 0.6)),
            trailing: Text(e['location'] ?? '', style: TextStyle(color: context.neutralMedium, fontSize: base * 0.6)),
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
