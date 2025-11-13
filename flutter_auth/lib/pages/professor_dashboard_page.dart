import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';
import '../models/event.dart';

class ProfessorDashboardPage extends StatefulWidget {
  const ProfessorDashboardPage({super.key});

  @override
  State<ProfessorDashboardPage> createState() => _ProfessorDashboardPageState();
}

class _ProfessorDashboardPageState extends State<ProfessorDashboardPage> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _teachingCourses = [];
  String? _selectedCourseId;
  bool _isLoading = true;
  late TabController _tabController;

  // Settings for EC conversion
  int _pointsPerPercent = 10; // 10 points = 1%
  double _maxExtraCreditPercent = 5.0; // Max 5% EC

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeachingCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachingCourses() async {
    // Demo mode: user is null, show mock data
    if (user == null) {
      setState(() => _isLoading = true);
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _teachingCourses = _getMockTeachingCourses();
        _selectedCourseId = _teachingCourses.isNotEmpty ? _teachingCourses[0]['sessionId'] : null;
        _isLoading = false;
      });
      return;
    }

    if (user?.email == null) return;

    setState(() => _isLoading = true);

    try {
      final teacherDoc = await FirebaseFirestore.instance
          .collection('teachers_dir')
          .doc(user!.email)
          .get();

      if (teacherDoc.exists) {
        final teacherData = teacherDoc.data()!;
        final sessions = List<Map<String, dynamic>>.from(
          teacherData['teachingSessions'] ?? []
        );

        setState(() {
          _teachingCourses = sessions;
          _selectedCourseId = sessions.isNotEmpty ? sessions[0]['sessionId'] : null;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading teaching courses: $e');
    }
  }

  /// Mock data for demo mode
  List<Map<String, dynamic>> _getMockTeachingCourses() {
    return [
      {
        'sessionId': 'demo_session_1',
        'courseCode': 'ECON 101',
        'courseName': 'Introduction to Microeconomics',
        'section': 'A',
        'semester': 'Fall 2024',
      },
      {
        'sessionId': 'demo_session_2',
        'courseCode': 'ECON 201',
        'courseName': 'Intermediate Macroeconomics',
        'section': 'B',
        'semester': 'Fall 2024',
      },
    ];
  }

  Map<String, dynamic>? get _selectedCourse {
    if (_selectedCourseId == null) return null;
    try {
      return _teachingCourses.firstWhere((c) => c['sessionId'] == _selectedCourseId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.neutralWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_teachingCourses.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: Column(
                  children: [
                    _buildCourseSelector(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStudentsList(),
                          _buildSettingsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? context.spacingM : context.spacingL,
        vertical: isSmallScreen ? context.spacingS : context.spacingM,
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
          SizedBox(width: isSmallScreen ? 0 : context.spacingL),
          const Spacer(),
          Text(
            'Extra Credit Dashboard',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: context.neutralBlack,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _showExportOptions,
            icon: Icon(
              IconlyBold.download,
              color: context.accentNavy,
              size: isSmallScreen ? 20 : 24,
            ),
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 36 : 48,
              minHeight: isSmallScreen ? 36 : 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(context.spacingXXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: context.accentNavy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyBold.document,
                  size: 56,
                  color: context.accentNavy,
                ),
              ),
              SizedBox(height: context.spacingXL),
              Text(
                'No Courses Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.neutralBlack,
                ),
              ),
              SizedBox(height: context.spacingM),
              Text(
                'Add courses in Manage Courses to start\ntracking student extra credit',
                style: TextStyle(
                  fontSize: 16,
                  color: context.neutralBlack.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacingXXL),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(IconlyBold.document),
                label: const Text('Manage Courses'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentNavy,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacingXL,
                    vertical: context.spacingL,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.radiusL),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseSelector() {
    if (_teachingCourses.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      margin: EdgeInsets.all(isSmallScreen ? context.spacingM : context.spacingL),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? context.spacingS : context.spacingM,
        vertical: isSmallScreen ? context.spacingXS : context.spacingS,
      ),
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedCourseId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: Icon(
          IconlyBold.arrow_down_2,
          color: context.neutralBlack,
          size: isSmallScreen ? 18 : 20,
        ),
        items: _teachingCourses.map((course) {
          final courseCode = course['courseCode'] ?? 'Unknown';
          final courseName = course['courseName'] ?? 'Unknown Course';
          final section = course['section'] ?? '';
          
          return DropdownMenuItem<String>(
            value: course['sessionId'],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$courseCode${section.isNotEmpty ? ' - $section' : ''}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack,
                  ),
                ),
                if (!isSmallScreen) ...[
                  SizedBox(height: context.spacingXS / 2),
                  Text(
                    courseName,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.neutralBlack.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCourseId = value;
          });
        },
      ),
    );
  }

  Widget _buildTabBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? context.spacingM : context.spacingL,
        vertical: isSmallScreen ? context.spacingXS : context.spacingS,
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
        labelStyle: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Students'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_selectedCourse == null) return const SizedBox.shrink();

    final courseCode = _selectedCourse!['courseCode'] ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('enrolledClasses', arrayContains: {
            'courseId': _selectedCourseId,
            'courseCode': courseCode,
          })
          .snapshots(),
      builder: (context, snapshot) {
        // Fallback: Manual query since arrayContains with map doesn't work
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getEnrolledStudents(courseCode),
          builder: (context, studentSnapshot) {
            if (studentSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!studentSnapshot.hasData || studentSnapshot.data!.isEmpty) {
              return _buildNoStudentsState();
            }

            final students = studentSnapshot.data!;

            final screenWidth = MediaQuery.of(context).size.width;
            final isSmallScreen = screenWidth < 600;
            
            return ListView.builder(
              padding: EdgeInsets.all(isSmallScreen ? context.spacingM : context.spacingL),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return _buildStudentCard(student);
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getEnrolledStudents(String courseCode) async {
    // Demo mode: user is null, return mock data
    if (user == null) {
      return _getMockStudents(courseCode);
    }

    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final enrolledStudents = <Map<String, dynamic>>[];

      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();
        final enrolledClasses = List<Map<String, dynamic>>.from(
          userData['enrolledClasses'] ?? []
        );

        // Check if student is enrolled in this course
        final isEnrolled = enrolledClasses.any((c) => 
          c['courseCode'] == courseCode
        );

        if (isEnrolled) {
          // Calculate EC for this student
          final points = userData['pointsBalance'] as int? ?? 0;
          final extraCreditPercent = _calculateExtraCreditPercent(points);

          enrolledStudents.add({
            'id': doc.id,
            'firstName': userData['firstName'] ?? 'Unknown',
            'lastName': userData['lastName'] ?? 'Student',
            'email': userData['email'] ?? '',
            'points': points,
            'extraCreditPercent': extraCreditPercent,
          });
        }
      }

      // Sort by points descending
      enrolledStudents.sort((a, b) => 
        (b['points'] as int).compareTo(a['points'] as int)
      );

      return enrolledStudents;
    } catch (e) {
      debugPrint('Error getting enrolled students: $e');
      return [];
    }
  }

  /// Mock student data for demo mode
  List<Map<String, dynamic>> _getMockStudents(String courseCode) {
    return [
      {
        'id': 'demo_student_1',
        'firstName': 'Sarah',
        'lastName': 'Johnson',
        'email': 'sarah.johnson@slu.edu',
        'points': 45,
        'extraCreditPercent': _calculateExtraCreditPercent(45),
      },
      {
        'id': 'demo_student_2',
        'firstName': 'Michael',
        'lastName': 'Chen',
        'email': 'michael.chen@slu.edu',
        'points': 38,
        'extraCreditPercent': _calculateExtraCreditPercent(38),
      },
      {
        'id': 'demo_student_3',
        'firstName': 'Emily',
        'lastName': 'Rodriguez',
        'email': 'emily.rodriguez@slu.edu',
        'points': 32,
        'extraCreditPercent': _calculateExtraCreditPercent(32),
      },
      {
        'id': 'demo_student_4',
        'firstName': 'James',
        'lastName': 'Williams',
        'email': 'james.williams@slu.edu',
        'points': 28,
        'extraCreditPercent': _calculateExtraCreditPercent(28),
      },
      {
        'id': 'demo_student_5',
        'firstName': 'Olivia',
        'lastName': 'Martinez',
        'email': 'olivia.martinez@slu.edu',
        'points': 25,
        'extraCreditPercent': _calculateExtraCreditPercent(25),
      },
      {
        'id': 'demo_student_6',
        'firstName': 'David',
        'lastName': 'Brown',
        'email': 'david.brown@slu.edu',
        'points': 20,
        'extraCreditPercent': _calculateExtraCreditPercent(20),
      },
      {
        'id': 'demo_student_7',
        'firstName': 'Sophia',
        'lastName': 'Davis',
        'email': 'sophia.davis@slu.edu',
        'points': 15,
        'extraCreditPercent': _calculateExtraCreditPercent(15),
      },
      {
        'id': 'demo_student_8',
        'firstName': 'Daniel',
        'lastName': 'Garcia',
        'email': 'daniel.garcia@slu.edu',
        'points': 10,
        'extraCreditPercent': _calculateExtraCreditPercent(10),
      },
    ];
  }

  double _calculateExtraCreditPercent(int points) {
    final percent = points / _pointsPerPercent;
    return percent > _maxExtraCreditPercent ? _maxExtraCreditPercent : percent;
  }

  Widget _buildNoStudentsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacingXXL),
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
              'No Students Enrolled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.neutralBlack.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: context.spacingM),
            Text(
              'Students who enroll in this course\nwill appear here',
              style: TextStyle(
                fontSize: 14,
                color: context.neutralBlack.withValues(alpha: 0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final firstName = student['firstName'] as String;
    final lastName = student['lastName'] as String;
    final email = student['email'] as String;
    final points = student['points'] as int;
    final ecPercent = student['extraCreditPercent'] as double;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? context.spacingS : context.spacingM),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radiusL),
          onTap: () => _showStudentDetails(student),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? context.spacingM : context.spacingL),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: isSmallScreen ? 24 : 28,
                  backgroundColor: context.accentNavy.withValues(alpha: 0.1),
                  child: Text(
                    '${firstName[0]}${lastName[0]}'.toUpperCase(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: context.accentNavy,
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? context.spacingS : context.spacingM),

                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: context.neutralBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isSmallScreen) ...[
                        SizedBox(height: context.spacingXS),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.neutralBlack.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                      SizedBox(height: isSmallScreen ? context.spacingXS : context.spacingS),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? context.spacingXS : context.spacingS,
                          vertical: isSmallScreen ? 2 : context.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: context.infoBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(context.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              IconlyBold.star,
                              size: isSmallScreen ? 10 : 12,
                              color: context.infoBlue,
                            ),
                            SizedBox(width: context.spacingXS / 2),
                            Text(
                              '$points pts',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: context.infoBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // EC Display
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? context.spacingS : context.spacingM,
                    vertical: isSmallScreen ? context.spacingXS : context.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: ecPercent > 0 
                        ? context.successGreen.withValues(alpha: 0.1)
                        : context.neutralGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${ecPercent.toStringAsFixed(isSmallScreen ? 1 : 2)}%',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 24,
                          fontWeight: FontWeight.w700,
                          color: ecPercent > 0 
                              ? context.successGreen
                              : context.neutralBlack.withValues(alpha: 0.5),
                        ),
                      ),
                      if (!isSmallScreen)
                        Text(
                          'EC',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.neutralBlack.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(width: isSmallScreen ? context.spacingS : context.spacingM),
                Icon(
                  IconlyLight.arrow_right_2,
                  color: context.neutralGray,
                  size: isSmallScreen ? 18 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? context.spacingM : context.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra Credit Conversion',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: context.neutralBlack,
            ),
          ),
          SizedBox(height: isSmallScreen ? context.spacingL : context.spacingXL),

          // Points per percent
          _buildSettingCard(
            icon: IconlyBold.star,
            title: 'Points Per Percent',
            subtitle: 'How many points = 1% extra credit',
            value: '$_pointsPerPercent points',
            onTap: () => _editPointsPerPercent(),
          ),

          SizedBox(height: isSmallScreen ? context.spacingM : context.spacingL),

          // Max EC
          _buildSettingCard(
            icon: IconlyBold.shield_done,
            title: 'Maximum Extra Credit',
            subtitle: 'Cap on total EC a student can earn',
            value: '${_maxExtraCreditPercent.toStringAsFixed(1)}%',
            onTap: () => _editMaxExtraCredit(),
          ),

          SizedBox(height: isSmallScreen ? context.spacingXL : context.spacingXXL),

          // Example calculation
          Container(
            padding: EdgeInsets.all(isSmallScreen ? context.spacingM : context.spacingL),
            decoration: BoxDecoration(
              color: context.infoBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.radiusL),
              border: Border.all(
                color: context.infoBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      IconlyBold.info_circle,
                      color: context.infoBlue,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    SizedBox(width: context.spacingS),
                    Text(
                      'Example',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: context.infoBlue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? context.spacingS : context.spacingM),
                Text(
                  '25 pts ÷ $_pointsPerPercent = ${(25 / _pointsPerPercent).toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack,
                  ),
                ),
                if ((25 / _pointsPerPercent) > _maxExtraCreditPercent) ...[
                  SizedBox(height: context.spacingXS),
                  Text(
                    'Capped at ${_maxExtraCreditPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: context.warningOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radiusL),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? context.spacingM : context.spacingL),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 40 : 48,
                  height: isSmallScreen ? 40 : 48,
                  decoration: BoxDecoration(
                    color: context.accentNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Icon(
                    icon,
                    color: context.accentNavy,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? context.spacingS : context.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: context.neutralBlack,
                        ),
                      ),
                      if (!isSmallScreen) ...[
                        SizedBox(height: context.spacingXS),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.neutralBlack.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? context.spacingS : context.spacingM,
                    vertical: isSmallScreen ? context.spacingXS : context.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: context.secondaryLight,
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: context.neutralBlack,
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? context.spacingS : context.spacingM),
                Icon(
                  IconlyLight.arrow_right_2,
                  color: context.neutralGray,
                  size: isSmallScreen ? 18 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editPointsPerPercent() {
    final controller = TextEditingController(text: _pointsPerPercent.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Points Per Percent'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Points needed for 1%',
            hintText: 'e.g., 10',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                setState(() {
                  _pointsPerPercent = value;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editMaxExtraCredit() {
    final controller = TextEditingController(text: _maxExtraCreditPercent.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Extra Credit'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Max EC percentage',
            hintText: 'e.g., 5.0',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                setState(() {
                  _maxExtraCreditPercent = value;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentDetailsSheet(
        student: student,
        courseCode: _selectedCourse!['courseCode'],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(context.spacingXL),
        decoration: BoxDecoration(
          color: context.neutralWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(context.radiusXL),
            topRight: Radius.circular(context.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.neutralBlack,
              ),
            ),
            SizedBox(height: context.spacingL),
            ListTile(
              leading: Icon(IconlyBold.document, color: context.accentNavy),
              title: const Text('Export to CSV'),
              subtitle: const Text('Download student EC data'),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV();
              },
            ),
            ListTile(
              leading: Icon(IconlyBold.send, color: context.accentNavy),
              title: const Text('Email Report'),
              subtitle: const Text('Send EC report to your email'),
              onTap: () {
                Navigator.pop(context);
                _emailReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV() async {
    // TODO: Implement CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV Export - Coming Soon!'),
        backgroundColor: context.accentNavy,
      ),
    );
  }

  Future<void> _emailReport() async {
    // TODO: Implement email report
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email Report - Coming Soon!'),
        backgroundColor: context.accentNavy,
      ),
    );
  }
}

// Student Details Sheet
class _StudentDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> student;
  final String courseCode;

  const _StudentDetailsSheet({
    required this.student,
    required this.courseCode,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = student['firstName'] as String;
    final lastName = student['lastName'] as String;
    final points = student['points'] as int;
    final ecPercent = student['extraCreditPercent'] as double;

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
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: context.accentNavy.withValues(alpha: 0.1),
                  child: Text(
                    '${firstName[0]}${lastName[0]}'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: context.accentNavy,
                    ),
                  ),
                ),
                SizedBox(height: context.spacingM),
                Text(
                  '$firstName $lastName',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: context.neutralBlack,
                  ),
                ),
                SizedBox(height: context.spacingS),
                Text(
                  student['email'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.neutralBlack.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: context.spacingL),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      context,
                      icon: IconlyBold.star,
                      label: 'Total Points',
                      value: '$points',
                      color: context.infoBlue,
                    ),
                    _buildStatCard(
                      context,
                      icon: IconlyBold.shield_done,
                      label: 'Extra Credit',
                      value: '${ecPercent.toStringAsFixed(2)}%',
                      color: context.successGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Events Attended
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _getStudentAttendedEvents(student['id']),
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
                          'No Events Attended',
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

                final events = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
                      child: Text(
                        'Events Attended (${events.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.neutralBlack,
                        ),
                      ),
                    ),
                    SizedBox(height: context.spacingM),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _buildEventItem(context, event);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(context.spacingL),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.radiusL),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: context.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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
      ),
    );
  }

  Future<List<Event>> _getStudentAttendedEvents(String studentId) async {
    try {
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('attendanceList', arrayContains: studentId)
          .orderBy('eventDate', descending: true)
          .get();

      return eventsSnapshot.docs
          .map((doc) => Event.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting attended events: $e');
      return [];
    }
  }

  Widget _buildEventItem(BuildContext context, Event event) {
    final eventDate = event.eventDate;
    final dateText = '${eventDate.month}/${eventDate.day}/${eventDate.year}';

    return Container(
      margin: EdgeInsets.only(bottom: context.spacingM),
      padding: EdgeInsets.all(context.spacingM),
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusM),
        border: Border.all(
          color: context.neutralGray.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.accentNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.radiusM),
            ),
            child: Icon(
              IconlyBold.calendar,
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
                  event.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.spacingXS),
                Row(
                  children: [
                    Text(
                      event.clubname,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.neutralBlack.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: context.neutralBlack.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 12,
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
              horizontal: context.spacingS,
              vertical: context.spacingXS,
            ),
            decoration: BoxDecoration(
              color: context.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconlyBold.tick_square,
                  size: 14,
                  color: context.successGreen,
                ),
                SizedBox(width: context.spacingXS),
                Text(
                  'Attended',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
