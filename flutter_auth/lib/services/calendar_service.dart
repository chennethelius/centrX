// lib/services/calendar_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Emits a map keyed by normalized DateTime(year,month,day) -> list of event maps.
/// Each event map contains fields useful for display (title, startTime, endTime, raw doc).
class CalendarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream that listens to the current user's document and, whenever the
  /// user's `events_registered` changes, fetches the corresponding event documents
  /// (supports top-level `events` collection OR events under club subcollections via collectionGroup).
  Stream<Map<DateTime, List<Map<String, dynamic>>>> userEventsByDateStream() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield <DateTime, List<Map<String, dynamic>>>{};
      return;
    }

    final userDocRef = _db.collection('users').doc(uid);

    await for (final userSnap in userDocRef.snapshots()) {
      final registered = List<String>.from(userSnap.data()?['events_registered'] ?? <dynamic>[]);

      if (registered.isEmpty) {
        yield <DateTime, List<Map<String, dynamic>>>{};
        continue;
      }

      // Fetch event docs in parallel
      final futures = registered.map((id) async {
        // Try top-level events collection first
        final top = await _db.collection('events').doc(id).get();
        if (top.exists) return top;

        // Fall back to collectionGroup search (events in subcollections, e.g. /clubs/{clubId}/events/{eventId})
        final cg = await _db.collectionGroup('events').where('eventId', isEqualTo: id).limit(1).get();
        if (cg.docs.isNotEmpty) return cg.docs.first;

        return null;
      }).toList();

      final docs = await Future.wait(futures);

      final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

      for (final doc in docs) {
        if (doc == null) continue;
        final data = doc.data() as Map<String, dynamic>;

        // Expect eventDate as Firestore Timestamp
        if (data['eventDate'] is Timestamp) {
          final ts = data['eventDate'] as Timestamp;
          final dt = ts.toDate();
          final key = DateTime(dt.year, dt.month, dt.day);

          final start = dt;
          DateTime? end;
          if (data['duration'] is int) {
            end = start.add(Duration(minutes: data['duration'] as int));
          } else if (data['endTime'] is Timestamp) {
            end = (data['endTime'] as Timestamp).toDate();
          }

          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add({
            'title': data['title'] ?? 'Untitled',
            'startTime': start,
            'endTime': end,
            'location': data['location'] ?? '',
            'clubId': data['clubId'] ?? '',
            'eventId': data['eventId'] ?? doc.id,
            'raw': data,
          });
        }
      }

      yield grouped;
    }
  }
}
