import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// FirebaseService - Complete Firestore Integration
/// Handles ALL database operations
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ═══════════════════════════════════════════════
  // USER PROFILE OPERATIONS
  // ═══════════════════════════════════════════════

  /// Create user profile in Firestore (called on signup)
  Future<void> createUserProfile({
    required String name,
    required String email,
  }) async {
    if (_uid == null) return;

    try {
      // ✅ FIXED: use set() with merge:true — safe whether doc exists or not
      await _db.collection('users').doc(_uid).set({
        'name': name,
        'email': email,
        'memberSince': FieldValue.serverTimestamp(),
        'education': 'Not set',
        'examPrep': 'Not set',
        'targetYear': 'Not set',
        'studyGoal': 'Not set',
        'totalStudySeconds': 0,
        'resourcesAccessed': 0,
        'questionsAttempted': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'lastActiveDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // ✅ merge: won't wipe existing data
      debugPrint('✅ User profile created in Firestore: $name');
    } catch (e) {
      debugPrint('❌ Error creating profile: $e');
      rethrow; // ✅ let caller know it failed
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_uid == null) return null;

    try {
      final doc = await _db.collection('users').doc(_uid).get();
      if (doc.exists && doc.data() != null) {
        debugPrint('✅ getUserProfile: loaded for $_uid');
        return doc.data();
      }

      // ✅ FIXED: Auto-create doc if missing (handles pre-Firestore signups)
      debugPrint('⚠️ No Firestore doc found — auto-creating from Auth data');
      final user = _auth.currentUser!;
      await createUserProfile(
        name: user.displayName ?? 'User',
        email: user.email ?? '',
      );
      // Fetch the freshly created doc
      final newDoc = await _db.collection('users').doc(_uid).get();
      return newDoc.data();
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      return null;
    }
  }

  /// Update user profile fields
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    if (_uid == null) return;

    try {
      fields['updatedAt'] = FieldValue.serverTimestamp();
      // ✅ FIXED: set+merge instead of update() — safe even if doc is missing
      await _db
          .collection('users')
          .doc(_uid)
          .set(fields, SetOptions(merge: true));
      debugPrint('✅ Profile updated: ${fields.keys.toList()}');
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════
  // STUDY TIME TRACKING
  // ═══════════════════════════════════════════════

  /// Start a study session (returns session ID)
  Future<String?> startStudySession(String screenName) async {
    if (_uid == null) return null;

    try {
      final docRef = await _db
          .collection('users')
          .doc(_uid)
          .collection('studySessions')
          .add({
        'screen': screenName,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'durationSeconds': 0,
      });
      debugPrint('▶️ Study session started: $screenName');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error starting session: $e');
      return null;
    }
  }

  /// End a study session and add to total
  Future<void> endStudySession(String sessionId, int durationSeconds) async {
    if (_uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('studySessions')
          .doc(sessionId)
          .update({
        'endTime': FieldValue.serverTimestamp(),
        'durationSeconds': durationSeconds,
      });

      // ✅ set+merge is safe for increment too if field somehow missing
      await _db.collection('users').doc(_uid).set({
        'totalStudySeconds': FieldValue.increment(durationSeconds),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('⏹️ Study session ended: $durationSeconds seconds');
    } catch (e) {
      debugPrint('❌ Error ending session: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // COUNTERS & TRACKING
  // ═══════════════════════════════════════════════

  Future<void> incrementResourcesAccessed() async {
    if (_uid == null) return;
    try {
      await _db.collection('users').doc(_uid).set({
        'resourcesAccessed': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('📚 Resource accessed');
    } catch (e) {
      debugPrint('❌ Error incrementing resources: $e');
    }
  }

  Future<void> incrementQuestionsAttempted() async {
    if (_uid == null) return;
    try {
      await _db.collection('users').doc(_uid).set({
        'questionsAttempted': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('❓ Question attempted');
    } catch (e) {
      debugPrint('❌ Error incrementing questions: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // STREAK MANAGEMENT
  // ═══════════════════════════════════════════════

  Future<void> updateStreak() async {
    if (_uid == null) return;

    try {
      final doc = await _db.collection('users').doc(_uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final now = DateTime.now();

      int currentStreak = data['currentStreak'] ?? 0;
      int longestStreak = data['longestStreak'] ?? 0;

      final lastActiveTimestamp = data['lastActiveDate'] as Timestamp?;

      if (lastActiveTimestamp != null) {
        final lastActive = lastActiveTimestamp.toDate();
        final diff = now.difference(lastActive).inDays;
        if (diff == 1) {
          currentStreak += 1;
        } else if (diff > 1) {
          currentStreak = 1;
        }
        // diff == 0 = same day, no change
      } else {
        currentStreak = 1;
      }

      if (currentStreak > longestStreak) longestStreak = currentStreak;

      // ✅ set+merge instead of update()
      await _db.collection('users').doc(_uid).set({
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActiveDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('🔥 Streak updated: $currentStreak days');
    } catch (e) {
      debugPrint('❌ Error updating streak: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // SECURITY QUESTIONS
  // ═══════════════════════════════════════════════

  Future<void> saveSecurityQuestions(
      List<Map<String, String>> questions) async {
    if (_uid == null) return;

    try {
      // ✅ FIXED: set+merge instead of update()
      await _db.collection('users').doc(_uid).set({
        'securityQuestions': questions,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Security questions saved');
    } catch (e) {
      debugPrint('❌ Error saving security questions: $e');
      rethrow;
    }
  }

  Future<bool> verifySecurityAnswer(String question, String answer) async {
    if (_uid == null) return false;

    try {
      final doc = await _db.collection('users').doc(_uid).get();
      if (!doc.exists) return false;

      final questions = List<Map<String, dynamic>>.from(
          doc.data()?['securityQuestions'] ?? []);

      for (final q in questions) {
        if (q['question'] == question &&
            q['answer'].toString().toLowerCase() ==
                answer.trim().toLowerCase()) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error verifying security answer: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // ACCOUNT MANAGEMENT
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return {'success': false, 'error': 'Not logged in'};
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthError(e.code)};
    }
  }

  Future<Map<String, dynamic>> deleteAccount({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return {'success': false, 'error': 'Not logged in'};
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete Firestore data first
      if (_uid != null) {
        await _db.collection('users').doc(_uid).delete();
      }

      await user.delete();
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthError(e.code)};
    }
  }

  // ═══════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> getSettings() async {
    if (_uid == null) return _defaultSettings();

    try {
      final doc = await _db.collection('users').doc(_uid).get();
      final data = doc.data() ?? {};
      // Merge with defaults so missing keys always have a value
      return {..._defaultSettings(), ...data};
    } catch (e) {
      debugPrint('❌ Error getting settings: $e');
      return _defaultSettings();
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (_uid == null) return;

    try {
      // ✅ FIXED: set+merge instead of update()
      // update() throws if the document or field doesn't exist yet
      await _db.collection('users').doc(_uid).set({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Setting saved: $key = $value');
    } catch (e) {
      debugPrint('❌ Error updating setting "$key": $e');
      rethrow; // ✅ bubble up so settings_screen can show error snackbar
    }
  }

  Map<String, dynamic> _defaultSettings() => {
        'dailyReminder': false,
        'examAlerts': true,
        'currentAffairsAlert': true,
        'reminderTime': '08:00 AM',
        'theme': 'System Default',
        'hapticFeedback': true,
        'defaultCategory': 'Not set',
        'language': 'en',
      };

  // ═══════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════

  String _getAuthError(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Incorrect password';
      case 'weak-password':
        return 'Password too weak (min 6 characters)';
      case 'requires-recent-login':
        return 'Please log in again first';
      default:
        return 'Error: $code';
    }
  }
}
