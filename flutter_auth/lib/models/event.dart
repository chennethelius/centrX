import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final int likeCount;
  final int commentCount;
  final int durationMinutes;
  final bool isQrEnabled;
  final bool isRsvped;
  final String eventId;
  final String ownerId;
  final String clubname;
  final String title;
  final String description;
  final String location;
  final DateTime createdAt;
  final DateTime eventDate;
  final List<String> mediaUrls;
  final List<String> attendanceList;
  final List<String> rsvpList;

  Event({
    required this.isQrEnabled,
    required this.durationMinutes,
    required this.likeCount,
    required this.commentCount,
    required this.isRsvped,
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
    required this.rsvpList,
  });

  /// Deserialize from Firestore document
  factory Event.fromJson(Map<String, dynamic> json, String id) {
    return Event(
      commentCount: json['commentCount']      as int?        ?? 0,
      likeCount:    json['likeCount']         as int?        ?? 0,
      isRsvped:     json['isRsvped']          as bool?       ?? false,
      eventId:        id,
      ownerId:       json['ownerId']       as String?        ?? '',
      clubname:      json['clubname']      as String?        ?? '',
      title:         json['title']         as String?        ?? '',
      description:   json['description']   as String?        ?? '',
      location:      json['location']      as String?        ?? '',
      createdAt:     (json['createdAt']    as Timestamp).toDate(),
      eventDate:     (json['eventDate']    as Timestamp).toDate(),
      durationMinutes: json['durationMinutes'] as int?            ?? 0,
      isQrEnabled:     json['isQrEnabled']     as bool?           ?? false,
      mediaUrls:     List<String>.from(json['mediaUrls']    as List<dynamic>? ?? []),
      attendanceList: List<String>.from(json['attendanceList'] as List<dynamic>? ?? []),
      rsvpList: List<String>.from(json['rsvpList'] as List<dynamic>? ?? []),
    );
  }

  /// Serialize to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'commentCount':   commentCount,
      'likeCount':      likeCount,
      'isRsvped':       isRsvped,
      'eventId':        eventId,
      'ownerId':        ownerId,
      'clubname':       clubname,
      'title':          title,
      'description':    description,
      'location':       location,
      'createdAt':      Timestamp.fromDate(createdAt),
      'eventDate':      Timestamp.fromDate(eventDate),
      'durationMinutes': durationMinutes,
      'isQrEnabled':     isQrEnabled,
      'mediaUrls':      mediaUrls,
      'attendanceList': attendanceList,
      'rsvpList': rsvpList,
    };
  }
}
