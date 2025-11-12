import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';
import '../models/event.dart';
import '../models/partnership.dart';
import '../services/partnership_service.dart';

class SupportEventPage extends StatefulWidget {
  const SupportEventPage({super.key});

  @override
  State<SupportEventPage> createState() => _SupportEventPageState();
}

class _SupportEventPageState extends State<SupportEventPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
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

            // Tab Bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: context.spacingXL),
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
                labelColor: Colors.white,
                unselectedLabelColor: context.neutralBlack.withValues(alpha: 0.6),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Individual Events'),
                  Tab(text: 'Club Partnerships'),
                ],
              ),
            ),

            SizedBox(height: context.spacingL),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIndividualEventsTab(),
                  _buildClubPartnershipsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualEventsTab() {
    return StreamBuilder<QuerySnapshot>(
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

  Widget _buildClubPartnershipsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'Please sign in',
          style: TextStyle(color: context.neutralDark),
        ),
      );
    }

    return Column(
      children: [
        // Create Partnership Button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreatePartnershipDialog(),
              icon: const Icon(IconlyBold.plus),
              label: const Text('Create New Partnership'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentNavy,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: context.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.radiusL),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacingL),

        // Partnerships List
        Expanded(
          child: StreamBuilder<List<Partnership>>(
            stream: PartnershipService.getTeacherPartnerships(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading partnerships',
                    style: TextStyle(color: context.errorRed),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
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
                        'Create a partnership to approve a club\nfor extra credit opportunities',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final partnerships = snapshot.data!;

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
                itemCount: partnerships.length,
                itemBuilder: (context, index) {
                  return _buildPartnershipCard(partnerships[index]);
                },
              );
            },
          ),
        ),
      ],
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
                  padding: EdgeInsets.all(context.spacingS),
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
                        partnership.clubName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.neutralBlack,
                        ),
                      ),
                      SizedBox(height: context.spacingXS),
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
                PopupMenuButton(
                  icon: Icon(
                    IconlyBold.more_circle,
                    color: context.neutralDark,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Edit'),
                      onTap: () => _showEditPartnershipDialog(partnership),
                    ),
                    PopupMenuItem(
                      child: Text(
                        'Deactivate',
                        style: TextStyle(color: context.errorRed),
                      ),
                      onTap: () => _deactivatePartnership(partnership.partnershipId),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: context.spacingM),
            Row(
              children: [
                _buildStatChip(
                  '${partnership.courses.first.pointsPerEvent} pts/event',
                  context.infoBlue,
                ),
                SizedBox(width: context.spacingS),
                _buildStatChip(
                  partnership.courses.first.maxEventsPerStudent == -1
                      ? 'Unlimited events'
                      : 'Max ${partnership.courses.first.maxEventsPerStudent} events',
                  context.successGreen,
                ),
                SizedBox(width: context.spacingS),
                _buildStatChip(
                  partnership.approvalMode == 'auto' ? 'Auto-approve' : 'Manual',
                  context.warningOrange,
                ),
              ],
            ),
            if (totalStudents > 0) ...[
              SizedBox(height: context.spacingM),
              Divider(color: context.neutralGray.withValues(alpha: 0.2)),
              SizedBox(height: context.spacingM),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalStudents',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.accentNavy,
                          ),
                        ),
                        Text(
                          'Students',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.neutralBlack.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalEvents',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.successGreen,
                          ),
                        ),
                        Text(
                          'Events Attended',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.neutralBlack.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacingS,
        vertical: context.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.radiusS),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _showCreatePartnershipDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get teacher's courses
    final teacherDoc = await FirebaseFirestore.instance
        .collection('teachers_dir')
        .doc(user.email)
        .get();

    if (!teacherDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Teacher profile not found'),
          backgroundColor: context.errorRed,
        ),
      );
      return;
    }

    final teacherData = teacherDoc.data()!;
    final teachingSessions = List<Map<String, dynamic>>.from(
      teacherData['teachingSessions'] ?? [],
    );

    if (teachingSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No courses found. Please add courses first.'),
          backgroundColor: context.errorRed,
        ),
      );
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreatePartnershipDialog(
        teacherId: user.uid,
        teacherName: '${teacherData['fullName'] ?? 'Teacher'}',
        teachingSessions: teachingSessions,
      ),
    );
  }

  Future<void> _showEditPartnershipDialog(Partnership partnership) async {
    // This will be implemented later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit partnership - Coming soon!'),
        backgroundColor: context.accentNavy,
      ),
    );
  }

  Future<void> _deactivatePartnership(String partnershipId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Partnership'),
        content: const Text(
          'Are you sure you want to deactivate this partnership? Students will no longer be able to earn points from this club\'s events.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Deactivate',
              style: TextStyle(color: context.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PartnershipService.deactivatePartnership(partnershipId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Partnership deactivated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: context.errorRed,
            ),
          );
        }
      }
    }
  }
}

/// Dialog for creating a new club partnership
class _CreatePartnershipDialog extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final List<Map<String, dynamic>> teachingSessions;

  const _CreatePartnershipDialog({
    required this.teacherId,
    required this.teacherName,
    required this.teachingSessions,
  });

  @override
  State<_CreatePartnershipDialog> createState() => _CreatePartnershipDialogState();
}

class _CreatePartnershipDialogState extends State<_CreatePartnershipDialog> {
  final TextEditingController _clubSearchController = TextEditingController();
  String _clubSearchQuery = '';
  String? _selectedClubId;
  String? _selectedClubName;
  final Set<String> _selectedCourseIds = {};
  final Map<String, int> _pointsPerCourse = {}; // courseId -> points
  final Map<String, int> _maxEventsPerCourse = {}; // courseId -> maxEvents (-1 for unlimited)
  String _approvalMode = 'auto';
  String _semester = _getCurrentSemester();
  bool _isLoading = false;

  static String _getCurrentSemester() {
    final now = DateTime.now();
    final month = now.month;
    if (month >= 1 && month <= 5) {
      return 'Spring${now.year}';
    } else if (month >= 6 && month <= 8) {
      return 'Summer${now.year}';
    } else {
      return 'Fall${now.year}';
    }
  }

  @override
  void dispose() {
    _clubSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.radiusXL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(context.spacingXL),
              child: Row(
                children: [
                  Text(
                    'Create Club Partnership',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.neutralBlack,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      IconlyBold.close_square,
                      color: context.neutralDark,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.spacingXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Club Selector
                    _buildClubSelector(),
                    SizedBox(height: context.spacingXL),

                    // Course Selection
                    _buildCourseSelection(),
                    SizedBox(height: context.spacingXL),

                    // Points & Max Events (shown per selected course)
                    if (_selectedCourseIds.isNotEmpty) ...[
                      _buildPointsAndMaxEvents(),
                      SizedBox(height: context.spacingXL),
                    ],

                    // Approval Mode
                    _buildApprovalMode(),
                    SizedBox(height: context.spacingXL),

                    // Semester
                    _buildSemesterSelector(),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: EdgeInsets.all(context.spacingXL),
              decoration: BoxDecoration(
                color: context.secondaryLight,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(context.radiusXL),
                  bottomRight: Radius.circular(context.radiusXL),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: context.neutralDark),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading || !_canCreate() ? null : _createPartnership,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentNavy,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.spacingXL,
                        vertical: context.spacingM,
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Partnership'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Club',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.neutralBlack,
          ),
        ),
        SizedBox(height: context.spacingM),
        TextField(
          controller: _clubSearchController,
          onChanged: (value) {
            setState(() {
              _clubSearchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search clubs...',
            prefixIcon: Icon(IconlyLight.search, color: context.neutralMedium),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.radiusM),
              borderSide: BorderSide(color: context.neutralGray),
            ),
          ),
        ),
        SizedBox(height: context.spacingM),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: context.neutralGray),
            borderRadius: BorderRadius.circular(context.radiusM),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('clubs').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final clubs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final clubName = (data['club_name'] as String? ?? '').toLowerCase();
                return clubName.contains(_clubSearchQuery);
              }).toList();

              if (clubs.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(context.spacingL),
                  child: Text(
                    'No clubs found',
                    style: TextStyle(color: context.neutralMedium),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: clubs.length,
                itemBuilder: (context, index) {
                  final clubDoc = clubs[index];
                  final clubData = clubDoc.data() as Map<String, dynamic>;
                  final clubId = clubDoc.id;
                  final clubName = clubData['club_name'] as String? ?? 'Unknown Club';
                  final isSelected = _selectedClubId == clubId;

                  return ListTile(
                    selected: isSelected,
                    title: Text(clubName),
                    subtitle: Text('${clubData['members_count'] ?? 0} members'),
                    trailing: isSelected
                        ? Icon(IconlyBold.tick_square, color: context.accentNavy)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedClubId = clubId;
                        _selectedClubName = clubName;
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Courses',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.neutralBlack,
          ),
        ),
        SizedBox(height: context.spacingS),
        Text(
          'Select which courses this partnership applies to',
          style: TextStyle(
            fontSize: 14,
            color: context.neutralBlack.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: context.spacingM),
        ...widget.teachingSessions.map((session) {
          final courseId = session['sessionId'] as String? ?? '';
          final courseCode = session['courseCode'] as String? ?? 'Unknown';
          final courseName = session['courseName'] as String? ?? 'Unknown Course';
          final isSelected = _selectedCourseIds.contains(courseId);

          return CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedCourseIds.add(courseId);
                  _pointsPerCourse[courseId] = 10; // Default points
                  _maxEventsPerCourse[courseId] = 5; // Default max events
                } else {
                  _selectedCourseIds.remove(courseId);
                  _pointsPerCourse.remove(courseId);
                  _maxEventsPerCourse.remove(courseId);
                }
              });
            },
            title: Text(
              courseCode,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.neutralBlack,
              ),
            ),
            subtitle: Text(
              courseName,
              style: TextStyle(
                fontSize: 12,
                color: context.neutralBlack.withValues(alpha: 0.6),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPointsAndMaxEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Points & Event Limits',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.neutralBlack,
          ),
        ),
        SizedBox(height: context.spacingM),
        ..._selectedCourseIds.map((courseId) {
          final session = widget.teachingSessions.firstWhere(
            (s) => s['sessionId'] == courseId,
          );
          final courseCode = session['courseCode'] as String? ?? 'Unknown';

          return Container(
            margin: EdgeInsets.only(bottom: context.spacingL),
            padding: EdgeInsets.all(context.spacingL),
            decoration: BoxDecoration(
              color: context.secondaryLight,
              borderRadius: BorderRadius.circular(context.radiusM),
              border: Border.all(color: context.neutralGray.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseCode,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack,
                  ),
                ),
                SizedBox(height: context.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Points per event',
                          hintText: '10',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(context.radiusM),
                          ),
                        ),
                        onChanged: (value) {
                          final points = int.tryParse(value) ?? 10;
                          setState(() {
                            _pointsPerCourse[courseId] = points;
                          });
                        },
                        controller: TextEditingController(
                          text: '${_pointsPerCourse[courseId] ?? 10}',
                        )..selection = TextSelection.fromPosition(
                            TextPosition(offset: '${_pointsPerCourse[courseId] ?? 10}'.length),
                          ),
                      ),
                    ),
                    SizedBox(width: context.spacingM),
                    Expanded(
                      child: _buildMaxEventsSelector(courseId),
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

  Widget _buildMaxEventsSelector(String courseId) {
    final maxEvents = _maxEventsPerCourse[courseId] ?? 5;
    final isUnlimited = maxEvents == -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Max events',
          style: TextStyle(
            fontSize: 12,
            color: context.neutralBlack.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: context.spacingXS),
        DropdownButtonFormField<int>(
          value: isUnlimited ? null : maxEvents,
          decoration: InputDecoration(
            hintText: isUnlimited ? 'Unlimited' : '$maxEvents',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.radiusM),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 1,
              child: const Text('1 event'),
            ),
            DropdownMenuItem(
              value: 2,
              child: const Text('2 events'),
            ),
            DropdownMenuItem(
              value: 3,
              child: const Text('3 events'),
            ),
            DropdownMenuItem(
              value: 4,
              child: const Text('4 events'),
            ),
            DropdownMenuItem(
              value: 5,
              child: const Text('5 events'),
            ),
            DropdownMenuItem(
              value: 10,
              child: const Text('10 events'),
            ),
            DropdownMenuItem(
              value: -1,
              child: const Text('Unlimited'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _maxEventsPerCourse[courseId] = value ?? 5;
            });
          },
        ),
      ],
    );
  }

  Widget _buildApprovalMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Approval Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.neutralBlack,
          ),
        ),
        SizedBox(height: context.spacingS),
        Text(
          'Auto-approve awards points immediately on QR scan. Manual requires review.',
          style: TextStyle(
            fontSize: 12,
            color: context.neutralBlack.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: context.spacingM),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'auto',
              label: Text('Auto-approve'),
            ),
            ButtonSegment(
              value: 'manual',
              label: Text('Manual'),
            ),
          ],
          selected: {_approvalMode},
          onSelectionChanged: (Set<String> selection) {
            setState(() {
              _approvalMode = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSemesterSelector() {
    final currentYear = DateTime.now().year;
    final semesters = [
      'Spring$currentYear',
      'Summer$currentYear',
      'Fall$currentYear',
      'Spring${currentYear + 1}',
      'Summer${currentYear + 1}',
      'Fall${currentYear + 1}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semester',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.neutralBlack,
          ),
        ),
        SizedBox(height: context.spacingM),
        DropdownButtonFormField<String>(
          value: _semester,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.radiusM),
            ),
          ),
          items: semesters.map((sem) {
            return DropdownMenuItem(
              value: sem,
              child: Text(sem),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _semester = value;
              });
            }
          },
        ),
      ],
    );
  }

  bool _canCreate() {
    return _selectedClubId != null &&
        _selectedCourseIds.isNotEmpty &&
        _pointsPerCourse.values.every((p) => p > 0);
  }

  Future<void> _createPartnership() async {
    if (!_canCreate()) return;

    setState(() => _isLoading = true);

    try {
      // Calculate expiration date (end of semester)
      final expiresAt = _calculateSemesterEnd(_semester);

      // Build courses list
      final courses = _selectedCourseIds.map((courseId) {
        final session = widget.teachingSessions.firstWhere(
          (s) => s['sessionId'] == courseId,
        );
        return PartnershipCourse(
          courseId: courseId,
          courseCode: session['courseCode'] as String? ?? 'Unknown',
          courseName: session['courseName'] as String? ?? 'Unknown Course',
          pointsPerEvent: _pointsPerCourse[courseId] ?? 10,
          maxEventsPerStudent: _maxEventsPerCourse[courseId] ?? 5,
        );
      }).toList();

      await PartnershipService.createPartnership(
        teacherId: widget.teacherId,
        teacherName: widget.teacherName,
        clubId: _selectedClubId!,
        clubName: _selectedClubName ?? 'Unknown Club',
        courses: courses,
        semester: _semester,
        approvalMode: _approvalMode,
        expiresAt: expiresAt,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partnership created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating partnership: $e'),
            backgroundColor: context.errorRed,
          ),
        );
      }
    }
  }

  DateTime _calculateSemesterEnd(String semester) {
    final now = DateTime.now();
    final year = int.tryParse(semester.substring(semester.length - 4)) ?? now.year;
    
    if (semester.startsWith('Spring')) {
      return DateTime(year, 5, 31); // End of May
    } else if (semester.startsWith('Summer')) {
      return DateTime(year, 8, 15); // Mid August
    } else {
      return DateTime(year, 12, 31); // End of December
    }
  }
}
