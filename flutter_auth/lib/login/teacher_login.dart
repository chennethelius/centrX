import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:flutter_auth/services/auth_service.dart';
import 'package:flutter_auth/pages/teacher_page.dart';
import '../theme/theme_extensions.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final TextEditingController _testEmailController = TextEditingController();

  @override
  void dispose() {
    _testEmailController.dispose();
    super.dispose();
  }

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
                'Teacher Login',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: context.neutralBlack,
                ),
              ),
              
              SizedBox(height: context.spacingM),
              
              Text(
                'Sign in with your SLU faculty Google account to access teacher tools.',
                style: TextStyle(
                  fontSize: 16,
                  color: context.neutralBlack.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              SizedBox(height: context.spacingXXL * 2),
              
              // Google Sign In Button for Teachers
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
                      // Use teacher-specific login flow
                      final user = await AuthService().teacherLogin();
                      if (!context.mounted) return;
                      
                      if (user != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ Teacher login success: ${user.email}')),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const TeacherPage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('❌ Teacher login failed - not a teacher or cancelled')),
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

              SizedBox(height: context.spacingXXL * 2),

              // TEST SECTION - Teacher Login Testing
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.spacingL),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(context.radiusL),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 TEST: Manual Teacher Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    SizedBox(height: context.spacingM),
                    
                    // Email input field
                    TextField(
                      controller: _testEmailController,
                      decoration: InputDecoration(
                        hintText: 'Enter SLU faculty email (e.g., john.smith@slu.edu)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.radiusM),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.spacingM,
                          vertical: context.spacingS,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    
                    SizedBox(height: context.spacingM),
                    
                    // Test button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final email = _testEmailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter an email address')),
                            );
                            return;
                          }
                          
                          // Test teacher login
                          final user = await AuthService().testTeacherLogin(email);
                          if (!context.mounted) return;
                          
                          if (user != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('✅ TEST: Teacher login success for $email')),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const TeacherPage()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ TEST: Email $email not found in teacher directory')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Test Teacher Login'),
                      ),
                    ),
                    
                    SizedBox(height: context.spacingM),
                    
                    // Direct navigation button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TeacherPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🎯 Go Directly to Teacher Page'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Footer text
              Center(
                child: Text(
                  'Create quests, track attendance, and manage student engagement.',
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
