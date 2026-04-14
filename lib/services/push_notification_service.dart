import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': newToken,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      developer.log(
        'FCM initialization skipped: $e',
        name: 'PushNotificationService',
      );
    }
  }
}
