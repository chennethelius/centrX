import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'student_login.dart';
import 'teacher_login.dart';
import '../theme/theme_extensions.dart';

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.neutralWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            IconlyBold.arrow_left_2,
            color: context.neutralBlack,
          ),
        ),
        title: Text(
          'centrX',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.neutralBlack,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.spacingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.spacingXXL),
              
              // Title
              Text(
                'Welcome to centrX',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.neutralBlack,
                  letterSpacing: -0.5,
                ),
              ),
              
              SizedBox(height: context.spacingM),
              
              Text(
                'Choose your account type to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: context.neutralBlack.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              SizedBox(height: context.spacingXXL * 2),
              
              // Student Login Button
              _buildLoginOption(
                context,
                icon: IconlyBold.user_2,
                title: 'Student',
                subtitle: 'Join events, earn points, connect with campus',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentLoginScreen()),
                  );
                },
              ),
              
              SizedBox(height: context.spacingL),
              
              // Teacher Login Button
              _buildLoginOption(
                context,
                icon: IconlyBold.document,
                title: 'Teacher',
                subtitle: 'Create quests, track attendance, manage engagement',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TeacherLoginScreen()),
                  );
                },
              ),
              
              const Spacer(),
              
              // Footer
              Center(
                child: Text(
                  'Transform your campus experience with centrX',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.neutralBlack.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: context.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
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
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.accentNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.radiusM),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: context.accentNavy,
                  ),
                ),
                SizedBox(width: context.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.neutralBlack,
                        ),
                      ),
                      SizedBox(height: context.spacingXS),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.neutralBlack.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  IconlyBold.arrow_right_2,
                  color: context.neutralBlack.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
