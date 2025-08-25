import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

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
              color: context.neutralWhite, // 60% - Primary neutral background
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
                        style: context.theme.textTheme.headlineMedium?.copyWith(
                          color: context.neutralBlack, // Primary neutral text color
                          fontWeight: FontWeight.w600,
                        ),
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
                                  color: context.accentNavy, // Navy accent for consistency
                                ),
                                BentoItem(
                                  title: 'Scheduled',
                                  value: '3',
                                  subtitle: '',
                                  icon: IconlyBold.time_circle,
                                  color: context.successGreen, // Status color for scheduled items
                                ),
                                BentoItem(
                                  title: 'Completed',
                                  value: '0',
                                  subtitle: '',
                                  icon: IconlyBold.tick_square,
                                  color: context.infoBlue, // Status color for completed items
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
        color: context.secondaryLight, // 30% - Secondary neutral for cards (matching points card)
        border: Border.all(
          color: context.neutralGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.spacingM),
            decoration: BoxDecoration(
              color: context.accentNavy, // Navy accent for the profile icon
              borderRadius: BorderRadius.circular(context.radiusL),
              boxShadow: [
                BoxShadow(
                  color: context.accentNavy.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                    color: context.neutralDark, // Neutral text color for light background
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  "$userFirstName!",
                  style: context.theme.textTheme.headlineLarge?.copyWith(
                    color: context.neutralBlack, // Darker text for emphasis
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(context.spacingS),
            decoration: BoxDecoration(
              color: context.errorRed, // Status color for notifications
              borderRadius: BorderRadius.circular(context.radiusM),
              boxShadow: [
                BoxShadow(
                  color: context.errorRed.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              IconlyBold.notification,
              color: Colors.white,
              size: context.spacingXL,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(int pointsBalance) {
    return Container(
      padding: EdgeInsets.all(context.spacingXL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.radiusHuge),
        color: context.secondaryLight, // 30% - Secondary neutral for cards
        border: Border.all(
          color: context.neutralGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: context.spacingXS),
                  child: Text(
                    '$pointsBalance',
                    style: context.theme.textTheme.displayLarge?.copyWith(
                      color: context.accentNavy, // Navy for emphasis
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(context.spacingS),
                decoration: BoxDecoration(
                  color: context.warningOrange, // Navy accent for the star icon
                  borderRadius: BorderRadius.circular(context.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: context.warningOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  IconlyBold.star,
                  color: Colors.white,
                  size: context.spacingXL,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
