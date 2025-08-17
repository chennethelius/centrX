import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:flutter_auth/services/auth_service.dart';
import 'package:flutter_auth/pages/club_page.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_theme.dart';

class ClubAdminLoginScreen extends StatefulWidget {
  const ClubAdminLoginScreen({super.key});

  @override
  State<ClubAdminLoginScreen> createState() => _ClubAdminLoginScreenState();
}

class _ClubAdminLoginScreenState extends State<ClubAdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              
              SizedBox(height: context.spacingXXL),
              
              // Email Field
              _buildTextField(
                controller: _emailController,
                hintText: 'E-mail',
                prefixIcon: IconlyBold.message,
              ),
              
              SizedBox(height: context.spacingL),
              
              // Password Field
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                prefixIcon: IconlyBold.lock,
                isPassword: true,
              ),
              
              SizedBox(height: context.spacingS),
              
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // Handle forgot password
                  },
                  child: Text(
                    'forgot password?',
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: context.neutralMedium,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: context.spacingXXL),
              
              // Login Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: context.accentNavy,
                  borderRadius: BorderRadius.circular(context.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: context.accentNavy.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(context.radiusL),
                    onTap: _isLoading ? null : () async {
                      // Validate input
                      if (_emailController.text.trim().isEmpty || 
                          _passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please enter both email and password'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);

                      try {
                        final user = await AuthService().signInClubWithEmail(
                          email: _emailController.text.trim(),
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
                            SnackBar(
                              content: const Text('Login failed - please check your credentials'),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        
                        String errorMessage = 'Login failed';
                        if (e.toString().contains('invalid-credential')) {
                          errorMessage = 'Invalid email or password. Please check your credentials.';
                        } else if (e.toString().contains('user-not-found')) {
                          errorMessage = 'No club account found with this email.';
                        } else if (e.toString().contains('wrong-password')) {
                          errorMessage = 'Incorrect password.';
                        } else if (e.toString().contains('invalid-email')) {
                          errorMessage = 'Please enter a valid email address.';
                        } else if (e.toString().contains('too-many-requests')) {
                          errorMessage = 'Too many failed attempts. Please try again later.';
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: AppTheme.errorRed,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Log In',
                              style: context.theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Divider with "or log in with"
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: context.neutralGray,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.spacingM),
                    child: Text(
                      'or log in with',
                      style: context.theme.textTheme.bodySmall?.copyWith(
                        color: context.neutralMedium,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: context.neutralGray,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: context.spacingL),
              
              // Social login buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialButton(Icons.g_mobiledata, 'Google'),
                  _buildSocialButton(Icons.apple, 'Apple'),

                ],
              ),
              
              SizedBox(height: context.spacingXXL),
              
              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.neutralMedium,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Sign up',
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: context.accentNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: context.spacingL),
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
      height: 56,
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: TextStyle(color: context.neutralBlack),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: context.neutralMedium),
          prefixIcon: Icon(
            prefixIcon,
            color: context.neutralMedium,
            size: 20,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                  icon: Icon(
                    _isPasswordVisible
                        ? IconlyBold.hide
                        : IconlyBold.show,
                    color: context.neutralMedium,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.spacingL,
            vertical: context.spacingL,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String platform) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: context.neutralGray,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radiusL),
          onTap: () {
            // Handle social login
            if (platform == 'Google') {
              // Handle Google login
            }
          },
          child: Icon(
            icon,
            color: context.neutralDark,
            size: 24,
          ),
        ),
      ),
    );
  }
}
