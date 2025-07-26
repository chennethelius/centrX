import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter_auth/services/auth_service.dart';
import 'package:flutter_auth/pages/club_page.dart';


class ClubAdminLoginScreen extends StatefulWidget {
  const ClubAdminLoginScreen({super.key});

  @override
  State<ClubAdminLoginScreen> createState() => _ClubAdminLoginScreenState();
}

class _ClubAdminLoginScreenState extends State<ClubAdminLoginScreen> {
  final _usernameController = TextEditingController();  // holds the email
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



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
                      'Club Login',
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
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                ),
                                child: const Icon(
                                  Icons.groups_outlined,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Title
                              const Text(
                                'Club Portal',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 12),

                              const Text(
                                'Sign in to access your club dashboard',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromRGBO(255, 255, 255, 0.8),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Username Field
                              _buildTextField(
                                controller: _usernameController,
                                hintText: 'Email',
                                prefixIcon: Icons.email_outlined,
                              ),

                              const SizedBox(height: 16),

                              // Password Field
                              _buildTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                              ),

                              const SizedBox(height: 32),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () async {
                                                setState(() => _isLoading = true);

                                                final user = await AuthService().signInClubWithEmail(
                                                  email: _usernameController.text.trim(),
                                                  password: _passwordController.text,
                                                );

                                                setState(() => _isLoading = false);

                                                if (user != null) {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ClubPage(),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Login failed')),
                                                  );
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color.fromRGBO(66, 66, 66, 1.0),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(),
                                              )
                                            : const Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.1),
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.fromBorderSide(
          BorderSide(
            color: Color.fromRGBO(255, 255, 255, 0.3),
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle:
              const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.7)),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color.fromRGBO(255, 255, 255, 0.7),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color.fromRGBO(255, 255, 255, 0.7),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
