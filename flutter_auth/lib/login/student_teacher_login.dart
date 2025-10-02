import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:flutter_auth/services/auth_service.dart';
import 'package:flutter_auth/components/app_shell.dart';
import 'package:flutter_auth/pages/teacher_page.dart';
import '../theme/theme_extensions.dart';

class StudentTeacherLoginScreen extends StatefulWidget {
  const StudentTeacherLoginScreen({super.key});

  @override
  State<StudentTeacherLoginScreen> createState() => _StudentTeacherLoginScreenState();
}

class _StudentTeacherLoginScreenState extends State<StudentTeacherLoginScreen> {
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
                'Login',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: context.neutralBlack,
                ),
              ),
              
              SizedBox(height: context.spacingXXL * 2),
              
              // Google Sign In Button (Student/Teacher)
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
                      try {
                        // trigger the Google sign-in flow:
                        final userCred = await AuthService().authenticateWithGoogle();
                        // Ensure the context is still mounted before navigation/snackbar.
                        if (!context.mounted) return;
                        // if successful, navigate to home; otherwise show an error:
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
                      } on SLUEmailRequiredException catch (e) {
                        if (!context.mounted) return;
                        
                        // Show SLU email requirement error snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sign-in error: ${e.toString()}')),
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.spacingL),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google icon (you can replace with actual Google logo)
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
                    
                    // Test buttons
                    Row(
                      children: [
                        Expanded(
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
                                // Navigate to teacher dashboard when ready
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AppShell()),
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
                        SizedBox(width: context.spacingS),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Test with real teacher login flow
                              final user = await AuthService().teacherLogin();
                              if (!context.mounted) return;
                              
                              if (user != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('✅ Real teacher login success: ${user.email}')),
                                );
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AppShell()),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('❌ Teacher login failed - not a teacher or cancelled')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Real Teacher Login'),
                          ),
                        ),
                      ],
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
            ],
          ),
        ),
      ),
    );
  }
}