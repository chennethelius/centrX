import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'student_teacher_login.dart';
import 'club_admin_login.dart';
import '../theme/theme_extensions.dart';

class NewLoginPage extends StatelessWidget {
  const NewLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.neutralWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.spacingXL),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // App Logo/Title
              Text(
                'centrX',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: context.neutralBlack,
                  letterSpacing: -0.5,
                ),
              ),
              
              const Spacer(flex: 1),
              
              // Sign up text
              Text(
                'Sign up',
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: context.neutralMedium,
                ),
              ),
              
              SizedBox(height: context.spacingL),
              
              // Welcome title
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: context.neutralMedium,
                  letterSpacing: 1,
                ),
              ),
              
              SizedBox(height: context.spacingL),
              
              // Subtitle
              Text(
                'Are you signing up as a',
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: context.neutralMedium,
                ),
              ),
              
              SizedBox(height: context.spacingXXL),
              
              // User type options
              _buildUserTypeOption(
                context: context,
                title: 'Student',
                icon: IconlyBold.profile,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentTeacherLoginScreen(),
                    ),
                  );
                },
              ),
              
              SizedBox(height: context.spacingL),
              
              _buildUserTypeOption(
                context: context,
                title: 'Professor',
                icon: IconlyBold.user_3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentTeacherLoginScreen(),
                    ),
                  );
                },
              ),
              
              SizedBox(height: context.spacingL),
              
              _buildUserTypeOption(
                context: context,
                title: 'Club',
                icon: IconlyBold.category,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClubAdminLoginScreen(),
                    ),
                  );
                },
              ),
              
              const Spacer(flex: 3),
              
              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Have an account? ',
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.neutralMedium,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to club login as it has the manual login
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClubAdminLoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Log in',
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: context.accentNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: context.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray,
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
            padding: EdgeInsets.symmetric(horizontal: context.spacingL),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: context.neutralDark,
                  size: 24,
                ),
                SizedBox(width: context.spacingL),
                Text(
                  title,
                  style: context.theme.textTheme.bodyLarge?.copyWith(
                    color: context.neutralBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}