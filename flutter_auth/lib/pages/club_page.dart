import 'package:flutter/material.dart';
import 'package:flutter_auth/pages/post_event_page.dart';
import '../components/event_card.dart';
import '../components/logout_button.dart';
import 'package:iconly/iconly.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_auth/components/bento_grid.dart';
import '../models/event.dart';
import '../theme/theme_extensions.dart';

class ClubPage extends StatefulWidget {
  const ClubPage({super.key});

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  final String clubName = FirebaseAuth.instance.currentUser?.displayName ?? '';
  final int memberCount = 47;

  Stream<List<Event>> _fetchClubEvents() {
    final user = FirebaseAuth.instance.currentUser;
    final clubId = user?.uid;

    return FirebaseFirestore.instance
        .collection('clubs')
        .doc(clubId)
        .collection('events')
        .orderBy('eventDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Event.fromJson(data, doc.id);
            }).toList());
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.neutralBlack,
          ),
        ),
        SizedBox(height: context.spacingL),
        StreamBuilder<List<Event>>(
          stream: _fetchClubEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: context.accentNavy,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: context.neutralDark),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: EdgeInsets.all(context.spacingXL),
                decoration: BoxDecoration(
                  color: context.secondaryLight,
                  borderRadius: BorderRadius.circular(context.radiusL),
                  border: Border.all(
                    color: context.neutralGray,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      IconlyBold.calendar,
                      size: 48,
                      color: context.neutralMedium,
                    ),
                    SizedBox(height: context.spacingM),
                    Text(
                      'No upcoming events',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.neutralMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: context.spacingS),
                    Text(
                      'Create your first event to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.secondaryDark,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return EventCard(event: snapshot.data![index]);
                },
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.neutralWhite,
      appBar: AppBar(
        backgroundColor: context.neutralWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Club Dashboard',
          style: TextStyle(
            color: context.neutralBlack,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              IconlyBold.notification,
              color: context.neutralDark,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              IconlyBold.setting,
              color: context.neutralDark,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(context.spacingL),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildClubHeader(),
                  SizedBox(height: context.spacingXL),
                  BentoGrid(
                    spacing: context.spacingM,
                    items: [
                      BentoItem(
                        title: 'Likes',
                        value: '0',
                        subtitle: '',
                        icon: IconlyBold.heart,
                        color: Colors.red,
                      ),
                      BentoItem(
                        title: 'Activity',
                        value: '0',
                        subtitle: '',
                        icon: IconlyBold.activity,
                        color: Colors.yellow,
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacingXL),
                  _buildEventsSection(),
                  SizedBox(height: context.spacingXXL * 2),
                  LogoutButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildClubHeader() {
    return Container(
      decoration: BoxDecoration(
        color: context.secondaryLight,
        borderRadius: BorderRadius.circular(context.radiusXL),
        border: Border.all(
          color: context.neutralGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.neutralGray.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(context.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.spacingL),
                decoration: BoxDecoration(
                  color: context.accentNavy,
                  borderRadius: BorderRadius.circular(context.radiusL),
                ),
                child: Icon(
                  IconlyBold.user_3,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(width: context.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $clubName',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.neutralBlack,
                      ),
                    ),
                    SizedBox(height: context.spacingXS),
                    Text(
                      '$memberCount members',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.neutralMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
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
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PostEventPage(),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          IconlyBold.plus,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
