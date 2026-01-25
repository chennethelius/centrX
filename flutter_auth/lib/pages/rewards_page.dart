import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';

import '../models/partnership.dart';
import '../theme/theme_extensions.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> _enrolledClasses = [];
  List<Partnership> _partnerships = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_user == null) {
      setState(() {
        _errorMessage = 'Not signed in';
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Get student's enrolled classes
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'User profile not found';
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final enrolledClasses = List<Map<String, dynamic>>.from(
        userData['enrolledClasses'] ?? [],
      );

      // 2. Get student's enrolled course codes
      final enrolledCourseCodes = enrolledClasses
          .map((c) => c['courseCode'] as String?)
          .where((code) => code != null && code.isNotEmpty)
          .cast<String>()
          .toSet();

      if (enrolledCourseCodes.isEmpty) {
        setState(() {
          _enrolledClasses = enrolledClasses;
          _partnerships = [];
          _isLoading = false;
        });
        return;
      }

      // 3. Query all active partnerships
      final partnershipSnapshot = await FirebaseFirestore.instance
          .collection('club_partnerships')
          .where('status', isEqualTo: 'active')
          .get();

      // 4. Filter partnerships that have courses matching student's enrolled courses
      final partnerships = partnershipSnapshot.docs
          .map((doc) => Partnership.fromJson(doc.data(), doc.id))
          .where((partnership) {
            // Check if any of the partnership's courses match the student's enrolled courses
            return partnership.courses.any(
              (course) => enrolledCourseCodes.contains(course.courseCode),
            );
          })
          .toList();

      setState(() {
        _enrolledClasses = enrolledClasses;
        _partnerships = partnerships;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading rewards data: $e');
      setState(() {
        _errorMessage = 'Failed to load data';
        _isLoading = false;
      });
    }
  }

  /// Get the courses from a partnership that match the student's enrolled courses
  List<PartnershipCourse> _getMatchingCourses(Partnership partnership) {
    final enrolledCourseCodes = _enrolledClasses
        .map((c) => c['courseCode'] as String?)
        .where((code) => code != null && code.isNotEmpty)
        .cast<String>()
        .toSet();

    return partnership.courses
        .where((course) => enrolledCourseCodes.contains(course.courseCode))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.neutralWhite,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: context.neutralWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconlyBold.danger,
                size: 48,
                color: context.errorRed,
              ),
              SizedBox(height: context.spacingM),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: context.neutralBlack.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: context.spacingL),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.neutralWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              // Content
              if (_enrolledClasses.isEmpty)
                SliverFillRemaining(
                  child: _buildNoCoursesState(),
                )
              else if (_partnerships.isEmpty)
                SliverFillRemaining(
                  child: _buildNoPartnershipsState(),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.all(context.spacingL),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPartnershipCard(_partnerships[index]),
                      childCount: _partnerships.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? context.spacingL : context.spacingXL),
      decoration: BoxDecoration(
        color: context.secondaryLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.spacingM),
                decoration: BoxDecoration(
                  color: context.accentNavy,
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
                child: Icon(
                  IconlyBold.star,
                  color: Colors.white,
                  size: isSmallScreen ? 24 : 28,
                ),
              ),
              SizedBox(width: context.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extra Credit',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 28,
                        color: context.neutralBlack,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.spacingXS / 2),
                    Text(
                      'Opportunities for your classes',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: context.neutralBlack.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingL),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacingL,
              vertical: context.spacingM,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.accentNavy,
                  context.accentNavy.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(context.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  IconlyBold.document,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: context.spacingM),
                Expanded(
                  child: Text(
                    '${_partnerships.length} club${_partnerships.length == 1 ? '' : 's'} offering EC for your ${_enrolledClasses.length} class${_enrolledClasses.length == 1 ? '' : 'es'}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCoursesState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconlyBold.document,
              size: 64,
              color: context.neutralGray,
            ),
            SizedBox(height: context.spacingL),
            Text(
              'No Classes Enrolled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.neutralBlack,
              ),
            ),
            SizedBox(height: context.spacingM),
            Text(
              'Enroll in classes on the Home page to see extra credit opportunities from partnered clubs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.neutralBlack.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPartnershipsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconlyBold.star,
              size: 64,
              color: context.neutralGray,
            ),
            SizedBox(height: context.spacingL),
            Text(
              'No Extra Credit Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.neutralBlack,
              ),
            ),
            SizedBox(height: context.spacingM),
            Text(
              'None of your enrolled classes have club partnerships yet. Check back later or ask your professors about extra credit opportunities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.neutralBlack.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: context.spacingL),
            // Show enrolled classes
            Container(
              padding: EdgeInsets.all(context.spacingL),
              decoration: BoxDecoration(
                color: context.neutralGray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(context.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Classes:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.neutralBlack.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: context.spacingS),
                  ..._enrolledClasses.map((c) => Padding(
                    padding: EdgeInsets.only(bottom: context.spacingXS),
                    child: Text(
                      '${c['courseCode']} - ${c['courseName']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.neutralBlack.withValues(alpha: 0.6),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnershipCard(Partnership partnership) {
    final matchingCourses = _getMatchingCourses(partnership);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Club header
          Container(
            padding: EdgeInsets.all(context.spacingL),
            decoration: BoxDecoration(
              color: context.accentNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.radiusL),
                topRight: Radius.circular(context.radiusL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.accentNavy,
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(partnership.clubName),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
                          fontWeight: FontWeight.w700,
                          color: context.neutralBlack,
                        ),
                      ),
                      SizedBox(height: context.spacingXS),
                      Row(
                        children: [
                          Icon(
                            IconlyBold.profile,
                            size: 14,
                            color: context.neutralBlack.withValues(alpha: 0.5),
                          ),
                          SizedBox(width: context.spacingXS),
                          Text(
                            'Prof. ${partnership.teacherName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.neutralBlack.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacingM,
                    vertical: context.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: context.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.radiusS),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.successGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Matching courses section
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Extra Credit for Your Classes:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: context.spacingM),
                ...matchingCourses.map((course) => _buildCourseChip(course)),
              ],
            ),
          ),

          // Info section
          Container(
            padding: EdgeInsets.all(context.spacingL),
            decoration: BoxDecoration(
              color: context.infoBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(context.radiusL),
                bottomRight: Radius.circular(context.radiusL),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconlyBold.info_circle,
                  size: 20,
                  color: context.infoBlue,
                ),
                SizedBox(width: context.spacingM),
                Expanded(
                  child: Text(
                    'Attend this club\'s events to earn extra credit automatically!',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.infoBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseChip(PartnershipCourse course) {
    final maxEvents = course.maxEventsPerStudent;
    final maxEventsText = maxEvents == -1 ? 'Unlimited events' : 'Max $maxEvents event${maxEvents == 1 ? '' : 's'}';

    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      padding: EdgeInsets.all(context.spacingM),
      decoration: BoxDecoration(
        color: context.neutralGray.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.radiusM),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacingS,
              vertical: context.spacingXS,
            ),
            decoration: BoxDecoration(
              color: context.infoBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.radiusS),
            ),
            child: Text(
              course.courseCode,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.infoBlue,
              ),
            ),
          ),
          SizedBox(width: context.spacingM),
          Expanded(
            child: Text(
              course.courseName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.neutralBlack,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacingS,
                  vertical: context.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: context.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.radiusS),
                ),
                child: Text(
                  '${course.pointsPerEvent} pts/event',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.successGreen,
                  ),
                ),
              ),
              SizedBox(height: context.spacingXS),
              Text(
                maxEventsText,
                style: TextStyle(
                  fontSize: 11,
                  color: context.neutralBlack.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
