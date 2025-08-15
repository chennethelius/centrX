import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'dart:ui';

import 'package:flutter_auth/components/bento_grid.dart';
import 'package:flutter_auth/components/logout_button.dart';
import 'package:flutter_auth/components/calendar_widget.dart';
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
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("No profile data found."),
                  LogoutButton(),
                ],
              ),
            );
          }

          final data = snap.data!.data()! as Map<String, dynamic>;
          final pointsBalance    = data['pointsBalance']    as int? ?? 0;

          return Container(
            decoration: BoxDecoration(
              gradient: context.backgroundGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.spacingXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: context.spacingL),

                    // Points label and card
                    Padding(
                      padding: EdgeInsets.only(left: context.spacingL),
                      child: Text(
                        'Points',
                        style: context.theme.textTheme.headlineMedium,
                      ),
                    ),
                    _buildPointsCard(pointsBalance),

                    SizedBox(height: context.spacingXXL),
                    if (user != null) ...[
                      SizedBox(height: context.spacingXXL),
                      // Calendar flexibility test: calendar (3/4) + bento grid (1/4)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Calendar widget (3/4 width)
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: EdgeInsets.only(right: context.spacingM),
                              child: const CalendarWidget(),
                            ),
                          ),
                          // Bento grid (1/4 width)
                          Expanded(
                            flex: 1,
                            child: BentoGrid(
                              spacing: context.spacingS,
                              items: [
                                BentoItem(
                                  title: 'Today',
                                  value: '1',
                                  subtitle: '',
                                  icon: IconlyBold.calendar,
                                  color: context.primaryCyan,
                                ),
                                BentoItem(
                                  title: 'Scheduled',
                                  value: '3',
                                  subtitle: '',
                                  icon: IconlyBold.time_circle,
                                  color: context.theme.colorScheme.secondary,
                                ),
                                BentoItem(
                                  title: 'Completed',
                                  value: '0',
                                  subtitle: '',
                                  icon: IconlyBold.tick_square,
                                  color: context.accentGold,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: context.spacingXXL),
                    LogoutButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(context.spacingXL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.radiusXXL),
        color: context.glassWhite(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radiusXXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.spacingM),
                decoration: BoxDecoration(
                  color: context.glassWhite(0.2),
                  borderRadius: BorderRadius.circular(context.radiusL),
                ),
                child: Icon(
                  IconlyBold.profile,
                  color: Colors.white,
                  size: context.spacingXXL,
                ),
              ),
              SizedBox(width: context.spacingL),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Welcome, ',
                      style: context.theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      "$userFirstName!",
                      style: context.theme.textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(context.spacingS),
                decoration: BoxDecoration(
                  color: context.glassWhite(0.2),
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
                child: Icon(
                  IconlyBold.notification,
                  color: Colors.white,
                  size: context.spacingXL,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard(int pointsBalance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '$pointsBalance',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      IconlyBold.star,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
