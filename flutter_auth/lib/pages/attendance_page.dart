import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';
import '../models/event.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
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
                    'Attendance Records',
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
                    hintText: 'Search past events...',
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
              child: _buildEventsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final eventDate = event.eventDate;
    final attendeeCount = event.attendanceList.length;
    final dateText = '${eventDate.month}/${eventDate.day}/${eventDate.year}';

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
          onTap: () => _showAttendanceDetails(context, event),
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

                // Footer with attendance count and location
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.spacingS,
                        vertical: context.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: attendeeCount > 0 
                            ? context.successGreen.withValues(alpha: 0.1)
                            : context.neutralGray.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconlyBold.user_2,
                            size: 14,
                            color: attendeeCount > 0 
                                ? context.successGreen
                                : context.neutralBlack.withValues(alpha: 0.5),
                          ),
                          SizedBox(width: context.spacingXS),
                          Text(
                            '$attendeeCount attendees',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: attendeeCount > 0 
                                  ? context.successGreen
                                  : context.neutralBlack.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      IconlyLight.location,
                      size: 16,
                      color: context.neutralBlack.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: context.spacingXS),
                    Flexible(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.neutralBlack.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildEventsList() {
    final user = FirebaseAuth.instance.currentUser;
    
    // Demo mode: show mock data
    if (user == null) {
      final mockEvents = _getMockPastEvents();
      final filteredEvents = mockEvents.where((event) {
        if (_searchQuery.isEmpty) return true;
        return event.title.toLowerCase().contains(_searchQuery) ||
               event.clubname.toLowerCase().contains(_searchQuery) ||
               event.description.toLowerCase().contains(_searchQuery);
      }).toList();

      if (filteredEvents.isEmpty) {
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
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return _buildEventCard(context, event);
        },
      );
    }

    // Real mode: query Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('eventDate', isLessThan: Timestamp.now())
          .orderBy('eventDate', descending: true)
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
                  'No past events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: context.spacingS),
                Text(
                  'Event attendance records will appear here',
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
    );
  }

  /// Mock past events for demo mode
  List<Event> _getMockPastEvents() {
    final now = DateTime.now();
    return [
      Event(
        eventId: 'demo_event_1',
        ownerId: 'demo_club_1',
        clubname: 'Economics Student Association',
        title: 'Microeconomics Workshop',
        description: 'Learn the fundamentals of supply and demand, market equilibrium, and consumer behavior in this interactive workshop.',
        location: 'Business School, Room 201',
        createdAt: now.subtract(const Duration(days: 10)),
        eventDate: now.subtract(const Duration(days: 5)),
        durationMinutes: 90,
        isQrEnabled: true,
        likeCount: 12,
        commentCount: 5,
        isRsvped: false,
        mediaUrls: [],
        attendanceList: ['demo_student_1', 'demo_student_2', 'demo_student_3', 'demo_student_4', 'demo_student_5'],
        rsvpList: ['demo_student_1', 'demo_student_2', 'demo_student_3', 'demo_student_4', 'demo_student_5', 'demo_student_6'],
      ),
      Event(
        eventId: 'demo_event_2',
        ownerId: 'demo_club_2',
        clubname: 'Business Analytics Club',
        title: 'Data Analysis Seminar',
        description: 'Explore data visualization techniques and statistical analysis methods used in modern business analytics.',
        location: 'Library, Conference Room B',
        createdAt: now.subtract(const Duration(days: 8)),
        eventDate: now.subtract(const Duration(days: 3)),
        durationMinutes: 120,
        isQrEnabled: true,
        likeCount: 18,
        commentCount: 8,
        isRsvped: false,
        mediaUrls: [],
        attendanceList: ['demo_student_2', 'demo_student_3', 'demo_student_6', 'demo_student_7'],
        rsvpList: ['demo_student_2', 'demo_student_3', 'demo_student_6', 'demo_student_7', 'demo_student_8'],
      ),
      Event(
        eventId: 'demo_event_3',
        ownerId: 'demo_club_1',
        clubname: 'Economics Student Association',
        title: 'Guest Speaker: Market Trends',
        description: 'Join us for an insightful talk by industry expert on current economic trends and their impact on global markets.',
        location: 'Auditorium, Main Hall',
        createdAt: now.subtract(const Duration(days: 15)),
        eventDate: now.subtract(const Duration(days: 7)),
        durationMinutes: 60,
        isQrEnabled: true,
        likeCount: 25,
        commentCount: 12,
        isRsvped: false,
        mediaUrls: [],
        attendanceList: ['demo_student_1', 'demo_student_4', 'demo_student_5', 'demo_student_6', 'demo_student_7', 'demo_student_8'],
        rsvpList: ['demo_student_1', 'demo_student_4', 'demo_student_5', 'demo_student_6', 'demo_student_7', 'demo_student_8'],
      ),
    ];
  }

  void _showAttendanceDetails(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AttendanceDetailsSheet(event: event),
    );
  }
}

class _AttendanceDetailsSheet extends StatelessWidget {
  final Event event;

  const _AttendanceDetailsSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final attendeeCount = event.attendanceList.length;
    final eventDate = event.eventDate;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: context.neutralWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.radiusXL),
          topRight: Radius.circular(context.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: context.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.neutralGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(context.spacingXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: context.neutralBlack,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _exportToCsv(context, event),
                      icon: Icon(
                        IconlyBold.download,
                        color: context.accentNavy,
                      ),
                      tooltip: 'Export to CSV',
                    ),
                  ],
                ),
                SizedBox(height: context.spacingS),
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
                    SizedBox(width: context.spacingS),
                    Text(
                      '${eventDate.month}/${eventDate.day}/${eventDate.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.neutralBlack.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacingL),
                Container(
                  padding: EdgeInsets.all(context.spacingM),
                  decoration: BoxDecoration(
                    color: attendeeCount > 0 
                        ? context.successGreen.withValues(alpha: 0.1)
                        : context.neutralGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        IconlyBold.user_2,
                        color: attendeeCount > 0 
                            ? context.successGreen
                            : context.neutralBlack.withValues(alpha: 0.5),
                      ),
                      SizedBox(width: context.spacingM),
                      Text(
                        '$attendeeCount Total Attendees',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: attendeeCount > 0 
                              ? context.successGreen
                              : context.neutralBlack.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Attendees List
          Expanded(
            child: attendeeCount == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconlyBold.user_2,
                          size: 64,
                          color: context.neutralGray,
                        ),
                        SizedBox(height: context.spacingL),
                        Text(
                          'No attendees recorded',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.neutralBlack.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: context.spacingS),
                        Text(
                          'This event had no recorded attendance',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.neutralBlack.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
                    itemCount: event.attendanceList.length,
                    itemBuilder: (context, index) {
                      final attendeeId = event.attendanceList[index];
                      return _buildAttendeeItem(context, attendeeId);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeItem(BuildContext context, String attendeeId) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Demo mode: show mock attendee data
    if (user == null) {
      final mockAttendee = _getMockAttendee(attendeeId);
      return Container(
        padding: EdgeInsets.symmetric(vertical: context.spacingM),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.neutralGray.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.accentNavy.withValues(alpha: 0.1),
              child: Text(
                '${mockAttendee['firstName']?[0] ?? 'U'}${mockAttendee['lastName']?[0] ?? 'S'}'.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.accentNavy,
                ),
              ),
            ),
            SizedBox(width: context.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${mockAttendee['firstName'] ?? 'Unknown'} ${mockAttendee['lastName'] ?? 'Student'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.neutralBlack,
                    ),
                  ),
                  Text(
                    mockAttendee['email'] ?? 'unknown@slu.edu',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.neutralBlack.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Real mode: query Firestore
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(attendeeId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: context.spacingM),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.neutralGray.withValues(alpha: 0.3),
                ),
                SizedBox(width: context.spacingM),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.neutralGray.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final firstName = userData?['firstName'] ?? 'Unknown';
        final lastName = userData?['lastName'] ?? 'User';
        final email = userData?['email'] ?? '';

        return Container(
          padding: EdgeInsets.symmetric(vertical: context.spacingM),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.neutralGray.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.accentNavy.withValues(alpha: 0.1),
                child: Text(
                  '${firstName[0]}${lastName[0]}'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.accentNavy,
                  ),
                ),
              ),
              SizedBox(width: context.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.neutralBlack,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Get mock attendee data by ID
  Map<String, String> _getMockAttendee(String attendeeId) {
    final mockAttendees = <String, Map<String, String>>{
      'demo_student_1': {'firstName': 'Sarah', 'lastName': 'Johnson', 'email': 'sarah.johnson@slu.edu'},
      'demo_student_2': {'firstName': 'Michael', 'lastName': 'Chen', 'email': 'michael.chen@slu.edu'},
      'demo_student_3': {'firstName': 'Emily', 'lastName': 'Rodriguez', 'email': 'emily.rodriguez@slu.edu'},
      'demo_student_4': {'firstName': 'James', 'lastName': 'Williams', 'email': 'james.williams@slu.edu'},
      'demo_student_5': {'firstName': 'Olivia', 'lastName': 'Martinez', 'email': 'olivia.martinez@slu.edu'},
      'demo_student_6': {'firstName': 'David', 'lastName': 'Brown', 'email': 'david.brown@slu.edu'},
      'demo_student_7': {'firstName': 'Sophia', 'lastName': 'Davis', 'email': 'sophia.davis@slu.edu'},
      'demo_student_8': {'firstName': 'Daniel', 'lastName': 'Garcia', 'email': 'daniel.garcia@slu.edu'},
    };
    return mockAttendees[attendeeId] ?? {'firstName': 'Unknown', 'lastName': 'Student', 'email': 'unknown@slu.edu'};
  }

  void _exportToCsv(BuildContext context, Event event) {
    // TODO: Implement CSV export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV Export - Coming Soon!'),
        backgroundColor: context.accentNavy,
      ),
    );
  }
}
