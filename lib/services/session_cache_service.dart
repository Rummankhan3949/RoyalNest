import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionSnapshot {
  const SessionSnapshot({required this.isLoggedIn, required this.role});

  final bool isLoggedIn;
  final String role;

  bool get isAdmin => role == 'admin';
  bool get isClient => role == 'client';
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.plotCount,
    required this.openQueries,
    required this.appointments,
    required this.unreadNotifications,
  });

  final int plotCount;
  final int openQueries;
  final int appointments;
  final int unreadNotifications;

  Map<String, dynamic> toMap() {
    return {
      'plotCount': plotCount,
      'openQueries': openQueries,
      'appointments': appointments,
      'unreadNotifications': unreadNotifications,
    };
  }

  factory DashboardSnapshot.fromMap(Map<String, dynamic> map) {
    return DashboardSnapshot(
      plotCount: map['plotCount'] ?? 0,
      openQueries: map['openQueries'] ?? 0,
      appointments: map['appointments'] ?? 0,
      unreadNotifications: map['unreadNotifications'] ?? 0,
    );
  }
}

class SessionCacheService {
  static const String _isLoggedInKey = 'session.isLoggedIn';
  static const String _roleKey = 'session.role';
  static const String _dashboardPrefix = 'dashboard.snapshot.';

  Future<SessionSnapshot> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionSnapshot(
      isLoggedIn: prefs.getBool(_isLoggedInKey) ?? false,
      role: prefs.getString(_roleKey) ?? '',
    );
  }

  Future<void> saveSession({
    required bool isLoggedIn,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    await prefs.setString(_roleKey, role);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_roleKey);
  }

  Future<DashboardSnapshot?> readDashboardSnapshot(String userId) async {
    if (userId.trim().isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_dashboardPrefix$userId');
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DashboardSnapshot.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDashboardSnapshot(
    String userId,
    DashboardSnapshot snapshot,
  ) async {
    if (userId.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_dashboardPrefix$userId',
      jsonEncode(snapshot.toMap()),
    );
  }
}
