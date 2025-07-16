import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'dart:ui';

class CalendarWidget extends StatefulWidget {
  /// dates to mark with an “event dot”
  final List<DateTime> rsvpDays;

  const CalendarWidget({
    Key? key,
    required this.rsvpDays,
  }) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                        color: Colors.white.withValues(alpha: 0.2),
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
          color: Colors.white.withValues(alpha: 0.1),
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
          children: weekdays.map((d) => Expanded(
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
          )).toList(),
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
              final hasEvent = widget.rsvpDays.any((d) => _isSameDay(d, thisDay));

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = thisDay),
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : isToday
                              ? Colors.white.withValues(alpha: 0.1)
                              : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
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
