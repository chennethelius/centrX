import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:flutter_auth/components/calendar_widget.dart';
import 'package:flutter_auth/components/class_enrollment_widget.dart';
import 'package:flutter_auth/theme/theme_extensions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  late final String userFirstName;

  @override
  void initState() {
    super.initState();
    final fullName = user?.displayName ?? '';
    userFirstName = fullName.isNotEmpty
        ? fullName.split(' ').first
        : 'there';
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    final uid = user?.uid;
    final userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();

    return Scaffold(
      backgroundColor: context.neutralWhite,
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No profile data found.",
                    style: TextStyle(color: context.neutralBlack),
                  ),
                ],
              ),
            );
          }

          final data = snap.data!.data()! as Map<String, dynamic>;
          final pointsBalance = data['pointsBalance'] as int? ?? 0;

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(pointsBalance),
                  SizedBox(height: context.spacingXL),
                  _buildCalendarSection(),
                  SizedBox(height: context.spacingXL),
                  if (user != null) ...[
                    _buildClassEnrollmentSection(uid!),
                    SizedBox(height: context.spacingXL),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int pointsBalance) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? context.spacingL : context.spacingXL),
      decoration: BoxDecoration(
        color: context.secondaryLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.spacingM),
                decoration: BoxDecoration(
                  color: context.accentNavy,
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
                child: Icon(
                  IconlyBold.profile,
                  color: Colors.white,
                  size: isSmallScreen ? 24 : 28,
                ),
              ),
              SizedBox(width: context.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: context.neutralBlack.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: context.spacingXS / 2),
                    Text(
                      "$userFirstName!",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 28,
                        color: context.neutralBlack,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(context.spacingS),
                decoration: BoxDecoration(
                  color: context.errorRed,
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
                child: Icon(
                  IconlyBold.notification,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingL),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacingL,
              vertical: context.spacingM,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.accentNavy,
                  context.accentNavy.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(context.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      IconlyBold.star,
                      color: Colors.white,
                      size: isSmallScreen ? 24 : 28,
                    ),
                    SizedBox(width: context.spacingM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$pointsBalance',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 28 : 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Points',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? context.spacingL : context.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendar',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: context.neutralBlack,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingL),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.spacingL),
            decoration: BoxDecoration(
              color: context.secondaryLight,
              borderRadius: BorderRadius.circular(context.radiusL),
              border: Border.all(
                color: context.neutralGray.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const CalendarWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassEnrollmentSection(String userId) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? context.spacingL : context.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Courses',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: context.neutralBlack,
            ),
          ),
          SizedBox(height: context.spacingL),
          ClassEnrollmentWidget(userId: userId),
        ],
      ),
    );
  }
}
