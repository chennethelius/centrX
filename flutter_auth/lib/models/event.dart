// lib/models/event.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String? eventId;
  final String ownerId;
  final String clubname;
  final String title;
  final String description;
  final String location;
  final DateTime createdAt;
  final DateTime eventDate;
  final List<String> mediaUrls;
  final List<String> attendanceList;

  Event({
    required this.eventId,
    required this.ownerId,
    required this.clubname,
    required this.title,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.eventDate,
    required this.mediaUrls,
    required this.attendanceList,
  });

  /// Deserialize from Firestore document
  factory Event.fromJson(Map<String, dynamic> json, String id) {
    return Event(
      eventId:        id,
      ownerId:       json['ownerId']       as String?        ?? '',
      clubname:      json['clubname']      as String?        ?? '',
      title:         json['title']         as String?        ?? '',
      description:   json['description']   as String?        ?? '',
      location:      json['location']      as String?        ?? '',
      createdAt:     (json['createdAt']    as Timestamp).toDate(),
      eventDate:     (json['eventDate']    as Timestamp).toDate(),
      mediaUrls:     List<String>.from(json['mediaUrls']    as List<dynamic>? ?? []),
      attendanceList: List<String>.from(json['attendanceList'] as List<dynamic>? ?? []),
    );
  }

  /// Serialize to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'ownerId':        ownerId,
      'clubname':       clubname,
      'title':          title,
      'description':    description,
      'location':       location,
      'createdAt':      Timestamp.fromDate(createdAt),
      'eventDate':      Timestamp.fromDate(eventDate),
      'mediaUrls':      mediaUrls,
      'attendanceList': attendanceList,
    };
  }
}
