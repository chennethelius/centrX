import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_auth/pages/post_event_page.dart';
import '../components/event_card.dart';
import '../components/logout_button.dart';
import 'package:iconly/iconly.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_auth/components/bento_grid.dart';
import '../models/event.dart';

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
        const Text(
          'Upcoming Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Event>>(
          stream: _fetchClubEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No upcoming events', style: TextStyle(color: Colors.white));
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
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                automaticallyImplyLeading: false,
                title: const Text(
                  'Club Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildClubHeader(),
                    const SizedBox(height: 24),
                    BentoGrid(
                      spacing: 16.0,
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
                    const SizedBox(height: 24),
                    _buildEventsSection(),
                    const SizedBox(height: 100),
                    LogoutButton(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildClubHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.all(Radius.circular(20)),
            border: Border.fromBorderSide(
              BorderSide(
                color: Color.fromRGBO(255, 255, 255, 0.3),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(255, 255, 255, 0.2),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $clubName',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$memberCount members',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromRGBO(255, 255, 255, 0.8),
                          ),
                        ),
                      ],
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

  Widget _buildFloatingActionButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(255, 255, 255, 0.3),
                Color.fromRGBO(255, 255, 255, 0.2),
              ],
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
            border: Border.fromBorderSide(
              BorderSide(
                color: Color.fromRGBO(255, 255, 255, 0.4),
                width: 1,
              ),
            ),
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
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
