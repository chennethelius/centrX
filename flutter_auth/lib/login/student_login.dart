import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:flutter_auth/services/auth_service.dart';
import 'package:flutter_auth/components/app_shell.dart';
import '../theme/theme_extensions.dart';

class StudentLoginScreen extends StatelessWidget {
  const StudentLoginScreen({super.key});

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
              
              // Login title
              Text(
                'Student Login',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: context.neutralBlack,
                ),
              ),
              
              SizedBox(height: context.spacingM),
              
              Text(
                'Sign in with your Google account to access events and earn points.',
                style: TextStyle(
                  fontSize: 16,
                  color: context.neutralBlack.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              SizedBox(height: context.spacingXXL * 2),
              
              // Google Sign In Button for Students
              Container(
                width: double.infinity,
                height: 56,
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
                    onTap: () async {
                      // Use student Google sign-in flow
                      final userCred = await AuthService().authenticateWithGoogle();
                      if (!context.mounted) return;
                      
                      if (userCred != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AppShell()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google sign-in failed or cancelled')),
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.spacingL),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google icon
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: context.accentNavy,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.g_mobiledata,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: context.spacingM),
                          Text(
                            'Continue with Google',
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
              ),
              
              const Spacer(),
              
              // Footer text
              Center(
                child: Text(
                  'Join events, earn points, and connect with your campus community.',
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
}
