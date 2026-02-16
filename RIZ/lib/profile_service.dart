import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

/// Profile Service - Manages user profile and usage statistics
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('profile_${user.uid}');

    if (profileJson != null) {
      return Map<String, dynamic>.from(json.decode(profileJson));
    }
    return null;
  }

  /// Save user profile data
  Future<void> saveUserProfile(Map<String, dynamic> profileData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_${user.uid}', json.encode(profileData));
  }

  /// Update when user accesses a resource (article, study material, etc.)
  Future<void> trackResourceAccessed() async {
    final profile = await getUserProfile();
    if (profile == null) return;

    profile['resourcesAccessed'] = (profile['resourcesAccessed'] ?? 0) + 1;
    await saveUserProfile(profile);
    print('📚 Resource accessed! Total: ${profile['resourcesAccessed']}');
  }

  /// Update when user attempts a question
  Future<void> trackQuestionAttempted() async {
    final profile = await getUserProfile();
    if (profile == null) return;

    profile['questionsAttempted'] = (profile['questionsAttempted'] ?? 0) + 1;
    await saveUserProfile(profile);
    print('❓ Question attempted! Total: ${profile['questionsAttempted']}');
  }

  /// Update study time (in minutes)
  Future<void> addStudyTime(int minutes) async {
    final profile = await getUserProfile();
    if (profile == null) return;

    profile['totalStudyTime'] = (profile['totalStudyTime'] ?? 0) + minutes;
    await saveUserProfile(profile);
    print(
      '⏱️ Study time added: $minutes min. Total: ${profile['totalStudyTime']} min',
    );
  }

  /// Update streak - call this when user uses app daily
  Future<void> updateStreak() async {
    final profile = await getUserProfile();
    if (profile == null) return;

    final now = DateTime.now();
    final lastActive = profile['lastActiveDate'] != null
        ? DateTime.parse(profile['lastActiveDate'])
        : null;

    if (lastActive != null) {
      final daysDifference = now.difference(lastActive).inDays;

      if (daysDifference == 1) {
        // Consecutive day - increase streak
        profile['currentStreak'] = (profile['currentStreak'] ?? 0) + 1;
        print('🔥 Streak increased! Current: ${profile['currentStreak']} days');
      } else if (daysDifference > 1) {
        // Missed days - reset streak
        profile['currentStreak'] = 1;
        print('🔥 Streak reset to 1');
      }
      // If same day (daysDifference == 0), don't change streak
    } else {
      // First time
      profile['currentStreak'] = 1;
    }

    profile['lastActiveDate'] = now.toIso8601String();
    await saveUserProfile(profile);
  }

  /// Increment multiple stats at once
  Future<void> trackActivity({
    bool accessedResource = false,
    bool attemptedQuestion = false,
    int studyMinutes = 0,
  }) async {
    if (accessedResource) await trackResourceAccessed();
    if (attemptedQuestion) await trackQuestionAttempted();
    if (studyMinutes > 0) await addStudyTime(studyMinutes);
    await updateStreak(); // Always update streak on activity
  }
}
