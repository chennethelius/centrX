import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'dart:ui';

import 'package:flutter_auth/components/bento_grid.dart';
import 'package:flutter_auth/components/logout_button.dart';
import 'package:flutter_auth/components/calendar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  late final String userFirstName;

  final List<DateTime> _rsvpDays = [
    DateTime.now().add(const Duration(days: 2)),
    DateTime.now().add(const Duration(days: 7)),
    DateTime.now().add(const Duration(days: 12)),
    DateTime.now().add(const Duration(days: 18)),
  ];

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
          final registeredEvents = List<String>.from(
            data['events_registered'] as List<dynamic>? ?? <dynamic>[],
          );
          final eventCount = registeredEvents.length;
          final clubsJoined       = data['clubs_joined']     as int? ?? 0;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 126, 203, 255),
                  Color(0xFF6366F1),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // static points card
                    _buildPointsCard(pointsBalance),

                    const SizedBox(height: 24),
                    BentoGrid(
                      items: [
                        BentoItem(
                          title: 'Events',
                          value: eventCount.toString(),
                          subtitle: 'Registered',
                          icon: IconlyBold.calendar,
                          color: Colors.red,
                        ),
                        BentoItem(
                          title: 'Clubs',
                          value: clubsJoined.toString(),
                          subtitle: 'Joined',
                          icon: IconlyBold.user_3,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (user != null) ...[
                      const SizedBox(height: 24),
                      const CalendarWidget(),
                    ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  IconlyBold.profile,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good morning ☀️',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userFirstName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  IconlyBold.notification,
                  color: Colors.white,
                  size: 20,
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
      padding: const EdgeInsets.all(24),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Points',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
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
                          const SizedBox(width: 12),
                          Text(
                            '$pointsBalance',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Gold Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '253 points to next reward',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
