import 'package:flutter/material.dart';
import 'package:flutter_auth/pages/post_event_page.dart';
import 'package:flutter_auth/pages/edit_event_page.dart';
import '../components/event_card.dart';
import 'package:iconly/iconly.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_auth/components/bento_grid.dart';
import '../models/event.dart';
import '../theme/theme_extensions.dart';
import '../services/event_service.dart';
import '../services/partnership_service.dart';
import '../models/partnership.dart';
import '../services/auth_service.dart';
import '../login/new_login_page.dart';

class ClubPage extends StatefulWidget {
  const ClubPage({super.key});

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Event>> _fetchClubEvents() {
    final clubId = user?.uid;
    if (clubId == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .orderBy('eventDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Event.fromJson(data, doc.id);
            }).toList());
  }

  Stream<List<Event>> _fetchUpcomingEvents() {
    final clubId = user?.uid;
    if (clubId == null) return Stream.value([]);

    final now = Timestamp.now();
    return FirebaseFirestore.instance
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .where('eventDate', isGreaterThan: now)
        .orderBy('eventDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Event.fromJson(data, doc.id);
            }).toList());
  }

  Stream<List<Event>> _fetchPastEvents() {
    final clubId = user?.uid;
    if (clubId == null) return Stream.value([]);

    final now = Timestamp.now();
    return FirebaseFirestore.instance
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .where('eventDate', isLessThan: now)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Event.fromJson(data, doc.id);
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: context.neutralWhite,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(), // Prevent swipe navigation
                  children: [
                    _buildOverviewTab(),
                    _buildEventsTab(),
                    _buildAnalyticsTab(),
                    _buildPartnershipsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacingL,
        vertical: context.spacingM,
      ),
      decoration: BoxDecoration(
        color: context.neutralWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 48), // Balance space
          const Spacer(),
          Text(
            'centrX',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.neutralBlack,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showLogoutDialog(),
            icon: Icon(
              IconlyBold.logout,
              color: context.neutralBlack,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.neutralBlack.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.errorRed,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Navigate first to prevent queries from continuing
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const NewLoginPage()),
        (route) => false,
      );
      // Then sign out (this happens after navigation)
      await AuthService().signOut();
    }
  }

  Widget _buildTabBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? context.spacingM : context.spacingL,
        vertical: context.spacingM,
      ),
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusM),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: context.accentNavy,
          borderRadius: BorderRadius.circular(context.radiusM),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: context.neutralBlack.withValues(alpha: 0.6),
        tabs: [
          Tab(
            icon: Icon(
              IconlyBold.chart,
              size: isSmallScreen ? 20 : 24,
            ),
            iconMargin: EdgeInsets.zero,
            height: isSmallScreen ? 44 : 48,
          ),
          Tab(
            icon: Icon(
              IconlyBold.calendar,
              size: isSmallScreen ? 20 : 24,
            ),
            iconMargin: EdgeInsets.zero,
            height: isSmallScreen ? 44 : 48,
          ),
          Tab(
            icon: Icon(
              IconlyBold.graph,
              size: isSmallScreen ? 20 : 24,
            ),
            iconMargin: EdgeInsets.zero,
            height: isSmallScreen ? 44 : 48,
          ),
          Tab(
            icon: Icon(
              IconlyBold.user_3,
              size: isSmallScreen ? 20 : 24,
            ),
            iconMargin: EdgeInsets.zero,
            height: isSmallScreen ? 44 : 48,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          SizedBox(height: context.spacingXL),
          _buildQuickStats(),
          SizedBox(height: context.spacingXL),
          _buildRecentActivity(),
          SizedBox(height: context.spacingXL),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final clubName = user?.displayName ?? 'Club';
    
    return Container(
      padding: EdgeInsets.all(context.spacingXL),
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.spacingL),
            decoration: BoxDecoration(
              color: context.accentNavy,
              borderRadius: BorderRadius.circular(context.radiusM),
            ),
            child: Icon(
              IconlyBold.user_3,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(width: context.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $clubName',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.neutralBlack,
                  ),
                ),
                SizedBox(height: context.spacingXS),
                Text(
                  'Manage your events and track engagement',
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

  Widget _buildQuickStats() {
    return StreamBuilder<List<Event>>(
      stream: _fetchClubEvents(),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        final now = DateTime.now();
        final upcoming = events.where((e) => e.eventDate.isAfter(now)).length;
        final totalAttendees = events.fold<int>(0, (sum, e) => sum + e.attendanceList.length);
        final totalRSVPs = events.fold<int>(0, (sum, e) => sum + e.rsvpList.length);

        return BentoGrid(
          spacing: context.spacingM,
          items: [
            BentoItem(
              title: 'Upcoming',
              value: '$upcoming',
              subtitle: 'Events',
              icon: IconlyBold.calendar,
              color: context.accentNavy,
            ),
            BentoItem(
              title: 'Total',
              value: '${events.length}',
              subtitle: 'Events',
              icon: IconlyBold.document,
              color: context.infoBlue,
            ),
            BentoItem(
              title: 'Attendees',
              value: '$totalAttendees',
              subtitle: 'Total',
              icon: IconlyBold.user_2,
              color: context.successGreen,
            ),
            BentoItem(
              title: 'RSVPs',
              value: '$totalRSVPs',
              subtitle: 'Total',
              icon: IconlyBold.tick_square,
              color: context.warningOrange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.neutralBlack,
          ),
        ),
        SizedBox(height: context.spacingL),
        StreamBuilder<List<Event>>(
          stream: _fetchClubEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: EdgeInsets.all(context.spacingXL),
                decoration: BoxDecoration(
                  color: context.secondaryLight,
                  borderRadius: BorderRadius.circular(context.radiusL),
                ),
                child: Column(
                  children: [
                    Icon(
                      IconlyBold.calendar,
                      size: 48,
                      color: context.neutralGray,
                    ),
                    SizedBox(height: context.spacingM),
                    Text(
                      'No events yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.neutralBlack.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: context.spacingS),
                    Text(
                      'Create your first event to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.neutralBlack.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            final events = snapshot.data!.take(3).toList();
            return Column(
              children: events.map((event) {
                return Container(
                  margin: EdgeInsets.only(bottom: context.spacingM),
                  child: EventCard(event: event),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: context.spacingL,
              vertical: context.spacingM,
            ),
            decoration: BoxDecoration(
              color: context.secondaryLight,
              borderRadius: BorderRadius.circular(context.radiusM),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: context.accentNavy,
                borderRadius: BorderRadius.circular(context.radiusM),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: context.neutralBlack.withValues(alpha: 0.6),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUpcomingEventsList(),
                _buildPastEventsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsList() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Event>>(
            stream: _fetchUpcomingEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                        'Create an event to get started',
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
                padding: EdgeInsets.all(context.spacingL),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final event = snapshot.data![index];
                  return _buildEventCardWithActions(event);
                },
              );
            },
          ),
        ),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildPastEventsList() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Event>>(
            stream: _fetchPastEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(context.spacingL),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final event = snapshot.data![index];
                  return _buildEventCardWithActions(event, showEdit: false);
                },
              );
            },
          ),
        ),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildEventCardWithActions(Event event, {bool showEdit = true}) {
    final eventDate = event.eventDate;
    final dateText = '${eventDate.month}/${eventDate.day}/${eventDate.year}';
    final attendeeCount = event.attendanceList.length;
    final rsvpCount = event.rsvpList.length;

    return Container(
      margin: EdgeInsets.only(bottom: context.spacingM),
      decoration: BoxDecoration(
        color: context.neutralWhite,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(context.spacingL),
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
                            event.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.neutralBlack,
                            ),
                          ),
                          SizedBox(height: context.spacingXS),
                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.neutralBlack.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showEdit && EventService().canModifyEvent(event))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editEvent(event),
                            icon: Icon(
                              IconlyBold.edit,
                              color: context.accentNavy,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteEvent(event),
                            icon: Icon(
                              IconlyBold.delete,
                              color: context.errorRed,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: context.spacingM),
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.neutralBlack.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.spacingM),
                Row(
                  children: [
                    _buildStatChip(
                      IconlyBold.user_2,
                      '$attendeeCount attendees',
                      context.successGreen,
                    ),
                    SizedBox(width: context.spacingM),
                    _buildStatChip(
                      IconlyBold.tick_square,
                      '$rsvpCount RSVPs',
                      context.infoBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacingS,
        vertical: context.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: context.spacingXS),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.neutralBlack,
            ),
          ),
          SizedBox(height: context.spacingXL),
          StreamBuilder<List<Event>>(
            stream: _fetchClubEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];
              final now = DateTime.now();
              final pastEvents = events.where((e) => e.eventDate.isBefore(now)).toList();
              
              if (pastEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconlyBold.graph,
                        size: 64,
                        color: context.neutralGray,
                      ),
                      SizedBox(height: context.spacingL),
                      Text(
                        'No analytics yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.neutralBlack.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: context.spacingS),
                      Text(
                        'Analytics will appear after events are completed',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final totalAttendees = pastEvents.fold<int>(0, (sum, e) => sum + e.attendanceList.length);
              final totalRSVPs = pastEvents.fold<int>(0, (sum, e) => sum + e.rsvpList.length);
              final avgAttendance = pastEvents.isNotEmpty ? (totalAttendees / pastEvents.length).round() : 0;
              final avgRSVP = pastEvents.isNotEmpty ? (totalRSVPs / pastEvents.length).round() : 0;
              final conversionRate = totalRSVPs > 0 ? ((totalAttendees / totalRSVPs) * 100).round() : 0;

              return Column(
                children: [
                  BentoGrid(
                    spacing: context.spacingM,
                    items: [
                      BentoItem(
                        title: 'Avg Attendance',
                        value: '$avgAttendance',
                        subtitle: 'per event',
                        icon: IconlyBold.user_2,
                        color: context.successGreen,
                      ),
                      BentoItem(
                        title: 'Avg RSVPs',
                        value: '$avgRSVP',
                        subtitle: 'per event',
                        icon: IconlyBold.tick_square,
                        color: context.infoBlue,
                      ),
                      BentoItem(
                        title: 'Conversion',
                        value: '$conversionRate%',
                        subtitle: 'RSVP → Attend',
                        icon: IconlyBold.graph,
                        color: context.warningOrange,
                      ),
                      BentoItem(
                        title: 'Total Events',
                        value: '${pastEvents.length}',
                        subtitle: 'completed',
                        icon: IconlyBold.document,
                        color: context.accentNavy,
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacingXL),
                  _buildEventPerformanceList(pastEvents),
                ],
              );
            },
          ),
          SizedBox(height: context.spacingXL),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildEventPerformanceList(List<Event> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.neutralBlack,
          ),
        ),
        SizedBox(height: context.spacingL),
        ...events.take(5).map((event) {
          final attendeeCount = event.attendanceList.length;
          final rsvpCount = event.rsvpList.length;
          final conversion = rsvpCount > 0 ? ((attendeeCount / rsvpCount) * 100).round() : 0;
          
          return Container(
            margin: EdgeInsets.only(bottom: context.spacingM),
            padding: EdgeInsets.all(context.spacingL),
            decoration: BoxDecoration(
              color: context.secondaryLight,
              borderRadius: BorderRadius.circular(context.radiusL),
              border: Border.all(
                color: context.neutralGray.withValues(alpha: 0.2),
              ),
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
                SizedBox(height: context.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem('Attendees', '$attendeeCount', context.successGreen),
                    ),
                    Expanded(
                      child: _buildMetricItem('RSVPs', '$rsvpCount', context.infoBlue),
                    ),
                    Expanded(
                      child: _buildMetricItem('Conversion', '$conversion%', context.warningOrange),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(height: context.spacingXS),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.neutralBlack.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnershipsTab() {
    final clubId = user?.uid;
    if (clubId == null) {
      return const Center(child: Text('Not signed in'));
    }

    return FutureBuilder<List<Partnership>>(
      future: PartnershipService.getClubPartnerships(clubId).catchError((error) {
        // Only log error if user is still authenticated (not logging out)
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          debugPrint('Error loading partnerships: $error');
        }
        // Suppress errors during logout
        return <Partnership>[]; // Return empty list on error
      }),
      builder: (context, snapshot) {
        // Check if user is still authenticated
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          // User logged out, don't show error
          return const SizedBox.shrink();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconlyBold.info_circle,
                        size: 64,
                        color: context.neutralGray,
                      ),
                      SizedBox(height: context.spacingL),
                      Text(
                        'Unable to load partnerships',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.neutralBlack.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: context.spacingS),
                      Text(
                        'Partnerships will appear here when\nteachers create them with your club',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              _buildLogoutButton(),
            ],
          );
        }

        final partnerships = snapshot.data ?? [];

        if (partnerships.isEmpty) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconlyBold.user_3,
                        size: 64,
                        color: context.neutralGray,
                      ),
                      SizedBox(height: context.spacingL),
                      Text(
                        'No partnerships yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.neutralBlack.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: context.spacingS),
                      Text(
                        'Teachers can create partnerships with your club\nfor extra credit opportunities',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              _buildLogoutButton(),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(context.spacingL),
                itemCount: partnerships.length,
                itemBuilder: (context, index) {
                  return _buildPartnershipCard(partnerships[index]);
                },
              ),
            ),
            _buildLogoutButton(),
          ],
        );
      },
    );
  }

  Widget _buildPartnershipCard(Partnership partnership) {
    final courseCodes = partnership.courses.map((c) => c.courseCode).join(', ');
    final totalStudents = partnership.stats.totalStudents;
    final totalEvents = partnership.stats.totalEventsAttended;

    return Container(
      margin: EdgeInsets.only(bottom: context.spacingL),
      decoration: BoxDecoration(
        color: context.neutralWhite,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.spacingM),
                  decoration: BoxDecoration(
                    color: context.accentNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Icon(
                    IconlyBold.user_3,
                    color: context.accentNavy,
                    size: 24,
                  ),
                ),
                SizedBox(width: context.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnership.teacherName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.neutralBlack,
                        ),
                      ),
                      Text(
                        courseCodes,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatChip(
                  partnership.approvalMode == 'auto' ? IconlyBold.tick_square : IconlyBold.time_circle,
                  partnership.approvalMode == 'auto' ? 'Auto' : 'Manual',
                  partnership.approvalMode == 'auto' ? context.successGreen : context.warningOrange,
                ),
              ],
            ),
            SizedBox(height: context.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem('Students', '$totalStudents', context.infoBlue),
                ),
                Expanded(
                  child: _buildMetricItem('Events', '$totalEvents', context.successGreen),
                ),
              ],
            ),
            SizedBox(height: context.spacingM),
            Text(
              'Semester: ${partnership.semester}',
              style: TextStyle(
                fontSize: 12,
                color: context.neutralBlack.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: context.accentNavy,
        borderRadius: BorderRadius.circular(context.radiusL),
        boxShadow: [
          BoxShadow(
            color: context.accentNavy.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PostEventPage(),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          IconlyBold.plus,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Future<void> _editEvent(Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(event: event),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: EdgeInsets.all(context.spacingL),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.errorRed,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: context.spacingXL,
            vertical: context.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radiusL),
          ),
        ),
        icon: const Icon(IconlyBold.logout, size: 20),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.neutralBlack.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await EventService().deleteEvent(event: event);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${event.title}" deleted successfully'),
              backgroundColor: context.successGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting event: $e'),
              backgroundColor: context.errorRed,
            ),
          );
        }
      }
    }
  }
}
