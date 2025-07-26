import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter_auth/services/auth_service.dart';
import 'package:flutter_auth/components/google_login_button.dart';
import 'package:flutter_auth/components/app_shell.dart';

class StudentTeacherLoginScreen extends StatelessWidget {
  const StudentTeacherLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Student Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.fromRGBO(255, 255, 255, 0.25),
                                Color.fromRGBO(255, 255, 255, 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: Color.fromRGBO(255, 255, 255, 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(255, 255, 255, 0.2),
                                  borderRadius: BorderRadius.all(Radius.circular(20)),
                                ),
                                child: const Icon(
                                  Icons.school_outlined,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Title
                              const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              const Text(
                                'Use your institutional Google account to access the platform',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromRGBO(255, 255, 255, 0.8),
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              
                              // Google Sign In Button
                              GoogleLoginButton(
                        icon: Icons.g_mobiledata,
                        label: 'Google',
                        onPressed: () async {
                          // trigger the Google sign-in flow:
                          final userCred = await AuthService().authenticateWithGoogle();
                          // if successful, navigate to home; otherwise show an error:
                          if (userCred != null) {
                            // after successful login
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const AppShell()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google sign-in failed or cancelled')),
                            );
                          }
                        },
                      ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}