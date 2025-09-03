import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';
import '../services/auth_service.dart';
import 'support_event_page.dart';
import 'attendance_page.dart';

class TeacherPage extends StatelessWidget {
  const TeacherPage({super.key});

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
        // Header with back button and logout
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
                SizedBox(width: 48), // Maintain spacing
            ],
          ),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacingXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.spacingL),

                // Welcome Section
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 16,
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
                        fontSize: 28,
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
                    fontSize: 16,
                    color: context.neutralBlack.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: context.spacingXXL * 2),

                // Features Grid
                Text(
                  'Teacher Tools',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack,
                  ),
                ),

                SizedBox(height: context.spacingL),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate number of columns based on screen width
                      final screenWidth = constraints.maxWidth;
                      final minCardWidth = 140.0; // Minimum width for each card
                      final crossAxisCount = (screenWidth / minCardWidth).floor().clamp(1, 3);
                      
                      // Calculate aspect ratio based on available space
                      final cardWidth = screenWidth / crossAxisCount - context.spacingL;
                      final aspectRatio = cardWidth / (cardWidth * 0.9); // Slightly taller than square
                      
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: context.spacingL,
                        mainAxisSpacing: context.spacingL,
                        childAspectRatio: aspectRatio,
                        padding: EdgeInsets.only(bottom: context.spacingXL),
                        children: [
                          _buildFeatureCard(
                            context,
                            icon: IconlyBold.document,
                            title: 'Support Event',
                            subtitle: 'Add point opportunities',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SupportEventPage(),
                              ),
                            ),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: IconlyBold.user_2,
                            title: 'Attendance',
                            subtitle: 'View student records',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AttendancePage(),
                              ),
                            ),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: IconlyBold.download,
                            title: 'Export Data',
                            subtitle: 'Download reports',
                            onTap: () => _showComingSoon(context, 'Export Data'),
                          ),
                          _buildFeatureCard(
                            context,
                            icon: IconlyBold.scan,
                            title: 'QR Codes',
                            subtitle: 'Generate quest QRs',
                            onTap: () => _showComingSoon(context, 'QR Codes'),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                SizedBox(height: context.spacingXL),
              ],
            ),
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

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
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
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.accentNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: context.accentNavy,
                  ),
                ),
                SizedBox(height: context.spacingM),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.neutralBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.spacingXS),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.neutralBlack.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: context.accentNavy,
      ),
    );
  }
}
