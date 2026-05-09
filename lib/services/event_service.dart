import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'events';
  static const String _sessionSeenPrefix = 'events.sessionSeen.';

  Stream<List<EventModel>> watchEvents() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final events = <EventModel>[];
          for (final doc in snapshot.docs) {
            try {
              events.add(EventModel.fromMap(doc.data(), doc.id));
            } catch (_) {
              // Skip malformed documents so one bad record doesn't break the list.
            }
          }

          events.sort((a, b) {
            final left = a.createdAt ?? a.startDate;
            final right = b.createdAt ?? b.startDate;
            return right.compareTo(left);
          });

          return events;
        });
  }

  Future<Map<String, dynamic>> createEvent(EventModel event) async {
    try {
      await _firestore.collection(_collection).add(event.toMap());
      return {'success': true};
    } on FirebaseException catch (e) {
      var message = 'Failed to create event. Try again.';
      if (e.code == 'permission-denied') {
        message =
            'Permission denied. Please sign in again with admin account and check Firestore rules deployment.';
      } else if (e.code == 'unavailable') {
        message = 'Network unavailable. Check internet and try again.';
      }
      return {'success': false, 'message': message};
    } catch (_) {
      return {
        'success': false,
        'message': 'Failed to create event. Try again.',
      };
    }
  }

  Future<bool> deactivateEvent(String eventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<EventModel?> getActiveEventForNow() async {
    try {
      final now = DateTime.now();
      final nowDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final ongoingEvents = <EventModel>[];
      final upcomingEvents = <EventModel>[];

      for (final doc in snapshot.docs) {
        try {
          final event = EventModel.fromMap(doc.data(), doc.id);
          if (!event.isActive) {
            continue;
          }

          final startDay = DateTime(
            event.startDate.year,
            event.startDate.month,
            event.startDate.day,
          );
          final endDay = DateTime(
            event.endDate.year,
            event.endDate.month,
            event.endDate.day,
          );

          // Ignore expired events.
          if (nowDay.isAfter(endDay)) {
            continue;
          }

          final isWithinWindow =
              !nowDay.isBefore(startDay) && !nowDay.isAfter(endDay);
          if (isWithinWindow) {
            ongoingEvents.add(event);
          } else {
            upcomingEvents.add(event);
          }
        } catch (_) {
          // Ignore malformed event documents.
        }
      }

      if (ongoingEvents.isNotEmpty) {
        ongoingEvents.sort((a, b) {
          final left = a.createdAt ?? a.startDate;
          final right = b.createdAt ?? b.startDate;
          return right.compareTo(left);
        });
        return ongoingEvents.first;
      }

      if (upcomingEvents.isNotEmpty) {
        upcomingEvents.sort((a, b) {
          final aStart = DateTime(
            a.startDate.year,
            a.startDate.month,
            a.startDate.day,
          );
          final bStart = DateTime(
            b.startDate.year,
            b.startDate.month,
            b.startDate.day,
          );
          final startCompare = aStart.compareTo(bStart);
          if (startCompare != 0) {
            return startCompare;
          }

          final left = a.createdAt ?? a.startDate;
          final right = b.createdAt ?? b.startDate;
          return right.compareTo(left);
        });
        return upcomingEvents.first;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> shouldShowEventThisLoginSession(EventModel event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (!event.isActive) {
      return false;
    }

    final now = DateTime.now();
    final nowDay = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(
      event.endDate.year,
      event.endDate.month,
      event.endDate.day,
    );
    if (nowDay.isAfter(endDay)) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final signInTime =
        user.metadata.lastSignInTime?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    final key = '$_sessionSeenPrefix${user.uid}.$signInTime';
    final seenEventId = prefs.getString(key);

    return seenEventId != event.id;
  }

  Future<void> markEventShownForSession(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final signInTime =
        user.metadata.lastSignInTime?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    final key = '$_sessionSeenPrefix${user.uid}.$signInTime';

    await prefs.setString(key, eventId);
  }
}
