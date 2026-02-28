import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

/// ProfileService - Thin caching layer over FirebaseService
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebase = FirebaseService();

  // ══════════════════════════════════════════════
  // CACHE
  // ══════════════════════════════════════════════

  Map<String, dynamic>? _cachedProfile;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  bool get _cacheValid =>
      _cachedProfile != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  void clearCache() {
    _cachedProfile = null;
    _cacheTime = null;
  }

  // ══════════════════════════════════════════════
  // PROFILE
  // ══════════════════════════════════════════════

  Future<Map<String, dynamic>?> getUserProfile(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValid) return _cachedProfile;

    // ✅ FIXED: FirebaseService.getUserProfile() now auto-creates doc if missing
    final data = await _firebase.getUserProfile();

    if (data != null) {
      _cachedProfile = data;
      _cacheTime = DateTime.now();
    } else {
      // Still null means user is not authenticated
      debugPrint('⚠️ ProfileService: getUserProfile returned null');
    }

    return data;
  }

  /// Get stats for home screen
  Future<Map<String, dynamic>> getUserStats() async {
    final profile = await getUserProfile(forceRefresh: true);
    final totalSeconds = profile?['totalStudySeconds'] ?? 0;

    return {
      'name': profile?['name'] ?? _auth.currentUser?.displayName ?? 'Learner',
      'totalStudySeconds': totalSeconds,
      'resourcesAccessed': profile?['resourcesAccessed'] ?? 0,
      'questionsAttempted': profile?['questionsAttempted'] ?? 0,
      'currentStreak': profile?['currentStreak'] ?? 0,
      'longestStreak': profile?['longestStreak'] ?? 0,
    };
  }

  // ══════════════════════════════════════════════
  // EMAIL MASKING
  // ══════════════════════════════════════════════

  String maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${'*' * name.length}@$domain';
    return '${name.substring(0, 2)}${'*' * (name.length - 2)}@$domain';
  }

  // ══════════════════════════════════════════════
  // TRACKING
  // ══════════════════════════════════════════════

  Future<void> updateStreak() async {
    if (_auth.currentUser == null) return;
    await _firebase.updateStreak();
    clearCache();
  }

  Future<void> trackResourceAccessed() async {
    if (_auth.currentUser == null) return;
    await _firebase.incrementResourcesAccessed();
    clearCache();
  }

  Future<void> trackQuestionFaced() async {
    if (_auth.currentUser == null) return;
    await _firebase.incrementQuestionsAttempted();
    clearCache();
  }

  // ══════════════════════════════════════════════
  // STUDY SESSION TRACKING
  // ══════════════════════════════════════════════

  String? _activeSessionId;
  DateTime? _sessionStartTime;

  Future<void> startStudySession(String screenName) async {
    if (_auth.currentUser == null) return;
    if (_activeSessionId != null) await endStudySession();

    _sessionStartTime = DateTime.now();
    _activeSessionId = await _firebase.startStudySession(screenName);
    debugPrint('▶️ Study started: $screenName');
  }

  Future<void> endStudySession() async {
    if (_activeSessionId == null || _sessionStartTime == null) return;

    final seconds = DateTime.now().difference(_sessionStartTime!).inSeconds;

    if (seconds >= 10) {
      await _firebase.endStudySession(_activeSessionId!, seconds);
      debugPrint('⏹️ Study ended: $seconds sec');
    }

    _activeSessionId = null;
    _sessionStartTime = null;
    clearCache();
  }

  String formatStudyTime(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (hours > 0) {
      return remainingMins > 0 ? '${hours}h ${remainingMins}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  // ══════════════════════════════════════════════
  // SECURITY QUESTIONS
  // ══════════════════════════════════════════════

  Future<void> saveSecurityQuestions(
      List<Map<String, String>> questions) async {
    await _firebase.saveSecurityQuestions(questions);
    clearCache();
  }

  Future<bool> verifySecurityAnswer(String question, String answer) async {
    return _firebase.verifySecurityAnswer(question, answer);
  }

  // ══════════════════════════════════════════════
  // ACCOUNT MANAGEMENT
  // ══════════════════════════════════════════════

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return _firebase.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Future<Map<String, dynamic>> deleteAccount({required String password}) async {
    return _firebase.deleteAccount(password: password);
  }

  /// Update profile fields — also syncs display name to Firebase Auth
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    await _firebase.updateProfile(fields);

    // Keep Firebase Auth displayName in sync
    if (fields.containsKey('name') && _auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(fields['name'] as String);
    }

    clearCache();
  }
}
