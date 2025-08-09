import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Streams normalized RSVP dates (YYYY-MM-DD) for the current user.
  Stream<List<DateTime>> rsvpDatesStream() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield <DateTime>[];
      return;
    }

    await for (final userSnap in _db.collection('users').doc(uid).snapshots()) {
      final registered = List<String>.from(
        userSnap.data()?['events_registered'] ?? <dynamic>[],
      );

      // Fetch all event docs in parallel
      final snaps = await Future.wait(
        registered.map((id) => _db.collection('events').doc(id).get()),
      );

      // Extract and normalize eventDate timestamps
      final dates = snaps
          .where((snap) =>
              snap.exists && snap.data()?['eventDate'] is Timestamp)
          .map((snap) {
            final ts = snap.data()!['eventDate'] as Timestamp;
            final dt = ts.toDate();
            return DateTime(dt.year, dt.month, dt.day);
          })
          .toList();

      yield dates;
    }
  }
}
