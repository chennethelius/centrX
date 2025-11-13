import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';
import '../services/auth_service.dart';
import 'support_event_page.dart';
import 'attendance_page.dart';
import 'teacher_course_management_page.dart';
import 'professor_dashboard_page.dart';

class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: context.neutralWhite,
      body: SafeArea(
        child: user == null
            ? _buildDemoTeacherUI(context)
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return _buildDemoTeacherUI(context);
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  return _buildAuthenticatedTeacherUI(context, userData);
                },
              ),
      ),
    );
  }

  Widget _buildAuthenticatedTeacherUI(BuildContext context, Map<String, dynamic> userData) {
    final firstName = userData['firstName'] ?? 'Teacher';
    final lastName = userData['lastName'] ?? '';
    final department = userData['department'] ?? 'Unknown Department';
    final school = userData['school'] ?? 'SLU';
    final isTestAccount = userData['isTestAccount'] ?? false;

    return _buildTeacherContent(
      context,
      firstName: firstName,
      lastName: lastName,
      department: department,
      school: school,
      isTestAccount: isTestAccount,
      showLogout: true,
    );
  }

  Widget _buildDemoTeacherUI(BuildContext context) {
    return _buildTeacherContent(
      context,
      firstName: 'Demo',
      lastName: 'Teacher',
      department: 'Economics',
      school: 'SLU Business',
      isTestAccount: false,
      isDemo: true,
      showLogout: false,
    );
  }

  Widget _buildTeacherContent(
    BuildContext context, {
    required String firstName,
    required String lastName,
    required String department,
    required String school,
    required bool isTestAccount,
    bool isDemo = false,
    bool showLogout = true,
  }) {
    return Column(
      children: [
        // Header
        Container(
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
          child: Column(
            children: [
              Row(
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
                    'centrX',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.neutralBlack,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (showLogout)
                    IconButton(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      icon: Icon(
                        IconlyBold.logout,
                        color: context.neutralBlack,
                      ),
                    )
                  else
                    SizedBox(width: 48),
                ],
              ),
              SizedBox(height: context.spacingS),
              // Welcome Section
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: context.spacingXS),
                      Row(
                        children: [
                          Text(
                            '$firstName $lastName',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: context.neutralBlack,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(width: context.spacingS),
                          if (isTestAccount)
                            _buildBadge('TEST', Colors.orange)
                          else if (isDemo)
                            _buildBadge('DEMO', context.accentNavy),
                        ],
                      ),
                      SizedBox(height: context.spacingXS),
                      Text(
                        '$department • $school',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tab Bar
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
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
                      IconlyBold.user_3,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    iconMargin: EdgeInsets.zero,
                    height: isSmallScreen ? 44 : 48,
                  ),
                  Tab(
                    icon: Icon(
                      IconlyBold.user_2,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    iconMargin: EdgeInsets.zero,
                    height: isSmallScreen ? 44 : 48,
                  ),
                  Tab(
                    icon: Icon(
                      IconlyBold.document,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    iconMargin: EdgeInsets.zero,
                    height: isSmallScreen ? 44 : 48,
                  ),
                ],
              ),
            );
          },
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Dashboard Tab
              const ProfessorDashboardPage(),
              
              // Partnerships Tab
              const SupportEventPage(),
              
              // Students Tab
              const AttendancePage(),
              
              // Courses Tab
              const TeacherCourseManagementPage(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

}
