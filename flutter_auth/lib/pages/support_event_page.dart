import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';
import '../models/event.dart';

class SupportEventPage extends StatefulWidget {
  const SupportEventPage({super.key});

  @override
  State<SupportEventPage> createState() => _SupportEventPageState();
}

class _SupportEventPageState extends State<SupportEventPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.neutralWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacingL,
                vertical: context.spacingM,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      IconlyBold.arrow_left_2,
                      color: context.neutralBlack,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Support Event',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.neutralBlack,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
              child: Container(
                decoration: BoxDecoration(
                  color: context.neutralGray.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.radiusL),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    hintStyle: TextStyle(
                      color: context.neutralBlack.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      IconlyLight.search,
                      color: context.neutralBlack.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.spacingL,
                      vertical: context.spacingM,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: context.spacingL),

            // Events List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('eventDate', isGreaterThan: Timestamp.now())
                    .orderBy('eventDate')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading events',
                        style: TextStyle(
                          color: context.errorRed,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconlyBold.calendar,
                            size: 64,
                            color: context.neutralGray,
                          ),
                          SizedBox(height: context.spacingL),
                          Text(
                            'No upcoming events',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.neutralBlack.withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(height: context.spacingS),
                          Text(
                            'Check back later for new events to support',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.neutralBlack.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final events = snapshot.data!.docs
                      .map((doc) => Event.fromJson(doc.data() as Map<String, dynamic>, doc.id))
                      .where((event) {
                    if (_searchQuery.isEmpty) return true;
                    return event.title.toLowerCase().contains(_searchQuery) ||
                           event.clubname.toLowerCase().contains(_searchQuery) ||
                           event.description.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconlyBold.search,
                            size: 64,
                            color: context.neutralGray,
                          ),
                          SizedBox(height: context.spacingL),
                          Text(
                            'No events found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.neutralBlack.withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(height: context.spacingS),
                          Text(
                            'Try adjusting your search terms',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.neutralBlack.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventCard(context, event);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final eventDate = event.eventDate;
    final now = DateTime.now();
    final isToday = eventDate.day == now.day &&
                   eventDate.month == now.month &&
                   eventDate.year == now.year;
    final isTomorrow = eventDate.day == now.add(const Duration(days: 1)).day &&
                      eventDate.month == now.add(const Duration(days: 1)).month &&
                      eventDate.year == now.add(const Duration(days: 1)).year;

    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isTomorrow) {
      dateText = 'Tomorrow';
    } else {
      dateText = '${eventDate.month}/${eventDate.day}/${eventDate.year}';
    }

    return Container(
      margin: EdgeInsets.only(bottom: context.spacingL),
      decoration: BoxDecoration(
        color: context.neutralWhite,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radiusL),
          onTap: () => _showSupportDialog(context, event),
          child: Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with club and date
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.spacingS,
                        vertical: context.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: context.accentNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.radiusS),
                      ),
                      child: Text(
                        event.clubname,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.accentNavy,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.neutralBlack.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.spacingM),

                // Event title
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack,
                  ),
                ),

                SizedBox(height: context.spacingS),

                // Event description
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.neutralBlack.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: context.spacingM),

                // Footer with location and time
                Row(
                  children: [
                    Icon(
                      IconlyLight.location,
                      size: 16,
                      color: context.neutralBlack.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: context.spacingXS),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.neutralBlack.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: context.spacingS),
                    Icon(
                      IconlyLight.time_circle,
                      size: 16,
                      color: context.neutralBlack.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: context.spacingXS),
                    Text(
                      '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.neutralBlack.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radiusL),
          ),
          title: Text(
            'Support Event',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.neutralBlack,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add point opportunities for:',
                style: TextStyle(
                  fontSize: 16,
                  color: context.neutralBlack.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: context.spacingM),
              Container(
                padding: EdgeInsets.all(context.spacingM),
                decoration: BoxDecoration(
                  color: context.neutralGray.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.neutralBlack,
                      ),
                    ),
                    SizedBox(height: context.spacingXS),
                    Text(
                      event.clubname,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.accentNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: context.neutralBlack.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to quest creation page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Quest creation - Coming Soon!'),
                    backgroundColor: context.accentNavy,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
              ),
              child: const Text('Create Quest'),
            ),
          ],
        );
      },
    );
  }
}
