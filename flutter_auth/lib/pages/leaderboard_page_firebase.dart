import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
import '../theme/theme_extensions.dart';

class LeaderboardPageFirebase extends StatefulWidget {
  const LeaderboardPageFirebase({super.key});

  @override
  State<LeaderboardPageFirebase> createState() =>
      _LeaderboardPageFirebaseState();
}

class _LeaderboardPageFirebaseState extends State<LeaderboardPageFirebase>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getWeeklyLeaderboard() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final data = entry.value.data();
        return {
          'rank': index,
          'uid': entry.value.id,
          'displayName': data['firstName'] ?? 'Student',
          'totalPoints': data['totalPoints'] ?? 0,
          'currentRank': data['currentRank'] ?? 0,
          'eventsAttended': data['eventsAttended'] ?? 0,
          'badges': (data['badges'] as List<dynamic>?)?.length ?? 0,
          'badge': _getMedalBadge(index),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getFriendsLeaderboard() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Get current user's followingClubs
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final followingClubs = 
          List<String>.from(userDoc.data()?['followingClubs'] ?? []);

      if (followingClubs.isEmpty) {
        return [];
      }

      // Get all users and filter
      final snapshot = await _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .get();

      final friendsList = snapshot.docs
          .where((doc) {
            final clubs =
                List<String>.from(doc.data()['followingClubs'] ?? []);
            return followingClubs.any((club) => clubs.contains(club));
          })
          .toList();

      return friendsList.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final data = entry.value.data();
        return {
          'rank': index,
          'uid': entry.value.id,
          'displayName': data['firstName'] ?? 'Student',
          'totalPoints': data['totalPoints'] ?? 0,
          'currentRank': data['currentRank'] ?? 0,
          'eventsAttended': data['eventsAttended'] ?? 0,
          'badges': (data['badges'] as List<dynamic>?)?.length ?? 0,
          'badge': _getMedalBadge(index),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching friends leaderboard: $e');
      return [];
    }
  }

  String _getMedalBadge(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '  ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.neutralLight,
      appBar: AppBar(
        backgroundColor: context.accentNavy,
        title: const Text('Leaderboard'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(child: Text('Global')),
            Tab(child: Text('Friends')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(
            future: _getWeeklyLeaderboard(),
            context: context,
          ),
          _buildLeaderboardTab(
            future: _getFriendsLeaderboard(),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab({
    required Future<List<Map<String, dynamic>>> future,
    required BuildContext context,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final leaderboard = snapshot.data ?? [];

        if (leaderboard.isEmpty) {
          return Center(
            child: Text(
              'No users yet',
              style: TextStyle(color: context.neutralMedium),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            vertical: context.spacingM,
            horizontal: context.spacingL,
          ),
          itemCount: leaderboard.length,
          itemBuilder: (context, index) {
            final user = leaderboard[index];
            return _buildLeaderboardItem(context, user);
          },
        );
      },
    );
  }

  Widget _buildLeaderboardItem(
      BuildContext context, Map<String, dynamic> user) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingM),
      padding: EdgeInsets.all(context.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.radiusL),
        border: Border.all(
          color: user['rank'] <= 3
              ? context.successGreen.withValues(alpha: 0.2)
              : Colors.grey.shade200,
          width: user['rank'] <= 3 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank/Medal
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: user['rank'] <= 3
                  ? context.successGreen.withValues(alpha: 0.1)
                  : context.neutralGray.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user['badge'] == '  '
                    ? '#${user['rank']}'
                    : user['badge'],
                style: TextStyle(
                  fontSize: user['badge'] == '  ' ? 14 : 20,
                  fontWeight: FontWeight.bold,
                  color: user['rank'] <= 3
                      ? context.successGreen
                      : context.neutralDark,
                ),
              ),
            ),
          ),
          SizedBox(width: context.spacingL),

          // Name and Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.neutralBlack,
                  ),
                ),
                SizedBox(height: context.spacingXS),
                Row(
                  children: [
                    Icon(
                      IconlyBold.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${user['totalPoints']} pts',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.neutralMedium,
                      ),
                    ),
                    SizedBox(width: context.spacingM),
                    Icon(
                      IconlyBold.calendar,
                      size: 14,
                      color: context.accentNavy,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${user['eventsAttended']} events',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.neutralMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Badges Count
          if (user['badges'] > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacingS,
                vertical: context.spacingXS,
              ),
              decoration: BoxDecoration(
                color: context.infoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(context.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconlyBold.badge,
                    size: 14,
                    color: context.infoBlue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${user['badges']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.infoBlue,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
