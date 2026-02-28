import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'firebase_service.dart';
import 'profile_service.dart';
import 'login_screen.dart'; // for post-logout navigation

// ─────────────────────────────────────────────
// Profile Screen
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebase = FirebaseService();
  final ProfileService _profileService = ProfileService();
  User? _currentUser;
  Map<String, dynamic>? _profileData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    // forceRefresh: true — always get latest from Firestore, skip cache
    final data = await _profileService.getUserProfile(forceRefresh: true);
    if (mounted)
      setState(() {
        _profileData = data;
        _loading = false;
      });
  }

  String _getMemberSince() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.metadata.creationTime == null) return 'Unknown';
    final date = user!.metadata.creationTime!;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Logout', style: TextStyle(fontFamily: 'Ubuntu')),
        content: Text('Are you sure?', style: TextStyle(fontFamily: 'Ubuntu')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(fontFamily: 'Ubuntu'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Logout',
                  style: TextStyle(color: Colors.red, fontFamily: 'Ubuntu'))),
        ],
      ),
    );
    if (confirm == true) {
      _profileService.clearCache();
      await _auth.signOut();
      if (mounted) {
        // ✅ Wipe entire navigation stack and go to LoginScreen
        // User cannot press back to get back into the app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthGate handles the unauthenticated case — nothing to do here

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout, color: Colors.white, size: 20),
                      label: Text('Logout',
                          style: TextStyle(
                              color: Colors.white, fontFamily: 'Ubuntu')),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : RefreshIndicator(
                        onRefresh: _loadProfile,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildProfileHeader(),
                              SizedBox(height: 24),
                              _buildAcademicProfile(),
                              SizedBox(height: 24),
                              _buildUsageStatistics(),
                              SizedBox(height: 24),
                              _buildSecuritySection(),
                              SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    // ✅ FIXED: Firestore is the ONLY source of truth for the name.
    // Priority: Firestore name → Auth displayName → email prefix → 'User'
    final firestoreName = (_profileData?['name'] as String?)?.trim() ?? '';
    final authName = _currentUser?.displayName?.trim() ?? '';
    final email = _currentUser?.email?.trim() ?? '';

    final name = firestoreName.isNotEmpty
        ? firestoreName
        : authName.isNotEmpty
            ? authName
            : email.isNotEmpty
                ? email.split('@')[0]
                : 'User';

    final maskedEmail = _profileService.maskEmail(email);
    final memberSince = _getMemberSince();

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF2196F3).withValues(alpha: 0.1),
            child: Text(
              name[0].toUpperCase(), // ✅ 'T' for Thiyagarajan, never 'U'
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                  fontFamily: 'Ubuntu'),
            ),
          ),
          SizedBox(height: 16),
          Text(name, // ✅ Full name shown — e.g. "Thiyagarajan"
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ubuntu')),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text(maskedEmail,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color ??
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'Ubuntu')),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text('Member since $memberSince',
                    style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Ubuntu')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicProfile() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Color(0xFF2196F3), size: 24),
              SizedBox(width: 12),
              Text('Academic Profile',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Ubuntu',
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Theme.of(context).colorScheme.onSurface)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF2196F3)),
                onPressed: _editAcademicProfile,
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoRow(
              Icons.book, 'Education', _profileData?['education'] ?? 'Not set'),
          SizedBox(height: 12),
          _buildInfoRow(Icons.workspace_premium, 'Exam Preparation',
              _profileData?['examPrep'] ?? 'Not set'),
          SizedBox(height: 12),
          _buildInfoRow(Icons.event, 'Target Year',
              _profileData?['targetYear'] ?? 'Not set'),
          SizedBox(height: 12),
          _buildInfoRow(Icons.flag, 'Study Goal',
              _profileData?['studyGoal'] ?? 'Not set'),
        ],
      ),
    );
  }

  Widget _buildUsageStatistics() {
    final totalSeconds = _profileData?['totalStudySeconds'] ?? 0;
    final studyTime = _profileService.formatStudyTime(totalSeconds);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF2196F3), size: 24),
              SizedBox(width: 12),
              Text('Usage Statistics',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Ubuntu')),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      studyTime, 'Study Time', Icons.timer, Colors.purple)),
              SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      '${_profileData?['resourcesAccessed'] ?? 0}',
                      'Resources',
                      Icons.library_books,
                      Colors.orange)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      '${_profileData?['questionsAttempted'] ?? 0}',
                      'Questions\nFaced',
                      Icons.quiz,
                      Colors.blue)),
              SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      '${_profileData?['currentStreak'] ?? 0} 🔥',
                      'Day Streak',
                      Icons.local_fire_department,
                      Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    final hasSecurityQuestions =
        (_profileData?['securityQuestions'] as List?)?.isNotEmpty ?? false;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Color(0xFF2196F3), size: 24),
              SizedBox(width: 12),
              Text('Security',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Ubuntu')),
            ],
          ),
          SizedBox(height: 20),
          _buildSecurityTile(
            icon: hasSecurityQuestions
                ? Icons.check_circle_rounded
                : Icons.help_outline_rounded,
            iconColor: hasSecurityQuestions ? Colors.green : Colors.orange,
            title: 'Security Questions',
            subtitle: hasSecurityQuestions
                ? 'Set up — used for password recovery'
                : 'Not set up — tap to configure',
            onTap: () => _setupSecurityQuestions(),
          ),
          Divider(height: 24),
          _buildSecurityTile(
            icon: Icons.lock_reset_rounded,
            iconColor: Color(0xFF2196F3),
            title: 'Change Password',
            subtitle: 'Requires your current password',
            onTap: () => _showChangePasswordDialog(),
          ),
          Divider(height: 24),
          _buildSecurityTile(
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.red,
            title: 'Delete Account',
            subtitle: 'Permanently removes all your data',
            onTap: () => _showDeleteAccountDialog(),
            titleColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Ubuntu',
                          color: titleColor ??
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              Theme.of(context).colorScheme.onSurface)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color ??
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFamily: 'Ubuntu')),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color ??
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'Ubuntu')),
              SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Ubuntu',
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Ubuntu')),
          SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color ??
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'Ubuntu')),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool oldVisible = false, newVisible = false, confirmVisible = false;
    bool loading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 20),
              Text('Change Password',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Ubuntu')),
              SizedBox(height: 4),
              Text('Enter your current password first',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color ??
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'Ubuntu')),
              SizedBox(height: 20),
              if (error != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(error!,
                            style: TextStyle(
                                color: Colors.red,
                                fontFamily: 'Ubuntu',
                                fontSize: 13))),
                  ]),
                ),
                SizedBox(height: 16),
              ],
              _buildPassField('Current Password', oldPassCtrl, oldVisible,
                  () => setModalState(() => oldVisible = !oldVisible)),
              SizedBox(height: 12),
              _buildPassField('New Password', newPassCtrl, newVisible,
                  () => setModalState(() => newVisible = !newVisible)),
              SizedBox(height: 12),
              _buildPassField(
                  'Confirm New Password',
                  confirmPassCtrl,
                  confirmVisible,
                  () => setModalState(() => confirmVisible = !confirmVisible)),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (newPassCtrl.text != confirmPassCtrl.text) {
                            setModalState(
                                () => error = 'New passwords do not match');
                            return;
                          }
                          if (newPassCtrl.text.length < 6) {
                            setModalState(() => error =
                                'Password must be at least 6 characters');
                            return;
                          }
                          setModalState(() {
                            loading = true;
                            error = null;
                          });
                          final result = await _profileService.changePassword(
                              oldPassword: oldPassCtrl.text,
                              newPassword: newPassCtrl.text);
                          setModalState(() => loading = false);
                          if (result['success']) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '✅ Password changed!',
                                          style:
                                              TextStyle(fontFamily: 'Ubuntu')),
                                      backgroundColor: Colors.green));
                            }
                          } else {
                            setModalState(() => error = result['error']);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Change Password',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showForgotPasswordViaSecurityQuestions();
                },
                child: Text('Forgot current password? Use security questions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2196F3),
                        fontFamily: 'Ubuntu')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassField(String label, TextEditingController ctrl, bool visible,
      VoidCallback toggleVisible) {
    return TextField(
      controller: ctrl,
      obscureText: !visible,
      style: TextStyle(fontFamily: 'Ubuntu'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Ubuntu', color: Colors.grey[600]),
        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF2196F3)),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey),
          onPressed: toggleVisible,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2196F3), width: 2)),
      ),
    );
  }

  void _showForgotPasswordViaSecurityQuestions() async {
    final profile = await _profileService.getUserProfile();
    final questions =
        List<Map<String, dynamic>>.from(profile?['securityQuestions'] ?? []);

    if (questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'No security questions set up. Please contact support.',
                style: TextStyle(fontFamily: 'Ubuntu')),
            backgroundColor: Colors.orange));
      }
      return;
    }

    final question = questions.first;
    final answerCtrl = TextEditingController();
    bool loading = false;
    String? error;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 20),
              Text('Verify Identity',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Ubuntu')),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.help_outline, color: Color(0xFF2196F3), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(question['question'] as String,
                          style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Ubuntu',
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Theme.of(context).colorScheme.onSurface))),
                ]),
              ),
              SizedBox(height: 16),
              if (error != null) ...[
                Text(error!,
                    style: TextStyle(
                        color: Colors.red, fontFamily: 'Ubuntu', fontSize: 13)),
                SizedBox(height: 10),
              ],
              TextField(
                controller: answerCtrl,
                style: TextStyle(fontFamily: 'Ubuntu'),
                decoration: InputDecoration(
                  labelText: 'Your Answer',
                  labelStyle:
                      TextStyle(fontFamily: 'Ubuntu', color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF2196F3), width: 2)),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setModalState(() {
                            loading = true;
                            error = null;
                          });
                          final verified =
                              await _profileService.verifySecurityAnswer(
                                  question['question'] as String,
                                  answerCtrl.text);
                          setModalState(() => loading = false);
                          if (verified) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: _currentUser!.email!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '✅ Password reset email sent!',
                                          style:
                                              TextStyle(fontFamily: 'Ubuntu')),
                                      backgroundColor: Colors.green));
                            }
                          } else {
                            setModalState(
                                () => error = 'Incorrect answer. Try again.');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Verify & Reset Password',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passCtrl = TextEditingController();
    bool loading = false;
    String? error;
    bool visible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_forever_rounded,
                      color: Colors.red, size: 24),
                ),
                SizedBox(width: 12),
                Text('Delete Account',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Ubuntu',
                        color: Colors.red)),
              ]),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '⚠️ This action is permanent and cannot be undone. All your data, progress, and profile will be permanently deleted.',
                  style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Ubuntu',
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Theme.of(context).colorScheme.onSurface,
                      height: 1.5),
                ),
              ),
              SizedBox(height: 20),
              if (error != null) ...[
                Text(error!,
                    style: TextStyle(
                        color: Colors.red, fontFamily: 'Ubuntu', fontSize: 13)),
                SizedBox(height: 10),
              ],
              _buildPassField('Enter your password to confirm', passCtrl,
                  visible, () => setModalState(() => visible = !visible)),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (passCtrl.text.isEmpty) {
                            setModalState(
                                () => error = 'Please enter your password');
                            return;
                          }
                          setModalState(() {
                            loading = true;
                            error = null;
                          });
                          final result = await _profileService.deleteAccount(
                              password: passCtrl.text);
                          if (result['success']) {
                            _profileService.clearCache();
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (_) => false,
                              );
                            }
                          } else {
                            setModalState(() {
                              loading = false;
                              error = result['error'];
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Delete My Account',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setupSecurityQuestions() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const SecurityQuestionsSetupScreen()));
    _loadProfile();
  }

  Future<void> _editAcademicProfile() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AcademicProfileEditor(currentData: _profileData ?? {})));
    if (result != null) {
      await _firebase.updateProfile(result);
      _profileService.clearCache();
      _loadProfile();
    }
  }
}

// ─────────────────────────────────────────────
// SECURITY QUESTIONS SETUP SCREEN
// ─────────────────────────────────────────────
class SecurityQuestionsSetupScreen extends StatefulWidget {
  const SecurityQuestionsSetupScreen({super.key});

  @override
  State<SecurityQuestionsSetupScreen> createState() =>
      _SecurityQuestionsSetupScreenState();
}

class _SecurityQuestionsSetupScreenState
    extends State<SecurityQuestionsSetupScreen> {
  final ProfileService _profileService = ProfileService();

  final List<String> _availableQuestions = [
    'What was the name of your first pet?',
    "What is your mother's maiden name?",
    'What city were you born in?',
    'What was the name of your first school?',
    "What is your oldest sibling's middle name?",
    'What was the make of your first car?',
    'What is the name of the street you grew up on?',
    'What was your childhood nickname?',
  ];

  String? _selectedQ1, _selectedQ2;
  final _answer1Ctrl = TextEditingController();
  final _answer2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _answer1Ctrl.dispose();
    _answer2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2196F3), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Security Questions',
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Ubuntu',
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 20),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Security questions are used to verify your identity if you forget your password.',
                      style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Ubuntu',
                          color: Theme.of(context).textTheme.bodyLarge?.color ??
                              Theme.of(context).colorScheme.onSurface,
                          height: 1.5))),
            ]),
          ),
          SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!,
                style: TextStyle(color: Colors.red, fontFamily: 'Ubuntu')),
            SizedBox(height: 12),
          ],
          _buildQuestionPicker('Question 1', _availableQuestions, _selectedQ1,
              (v) => setState(() => _selectedQ1 = v), _answer1Ctrl),
          SizedBox(height: 20),
          _buildQuestionPicker(
              'Question 2',
              _availableQuestions.where((q) => q != _selectedQ1).toList(),
              _selectedQ2,
              (v) => setState(() => _selectedQ2 = v),
              _answer2Ctrl),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2196F3),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Save Security Questions',
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPicker(
      String label,
      List<String> questions,
      String? selected,
      ValueChanged<String?> onChanged,
      TextEditingController answerCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Ubuntu',
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              hint: Text('Choose a question',
                  style: TextStyle(
                      color: Theme.of(context).dividerColor,
                      fontFamily: 'Ubuntu')),
              style: TextStyle(
                  fontFamily: 'Ubuntu',
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize: 14),
              items: questions
                  .map((q) => DropdownMenuItem(
                      value: q,
                      child: Text(q,
                          style:
                              TextStyle(fontFamily: 'Ubuntu', fontSize: 13))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: answerCtrl,
          style: TextStyle(fontFamily: 'Ubuntu'),
          decoration: InputDecoration(
            labelText: 'Your Answer',
            labelStyle:
                TextStyle(fontFamily: 'Ubuntu', color: Colors.grey[600]),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF2196F3), width: 2)),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedQ1 == null || _selectedQ2 == null) {
      setState(() => _error = 'Please select both questions');
      return;
    }
    if (_answer1Ctrl.text.trim().isEmpty || _answer2Ctrl.text.trim().isEmpty) {
      setState(() => _error = 'Please answer both questions');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await _profileService.saveSecurityQuestions([
      {
        'question': _selectedQ1!,
        'answer': _answer1Ctrl.text.trim().toLowerCase()
      },
      {
        'question': _selectedQ2!,
        'answer': _answer2Ctrl.text.trim().toLowerCase()
      },
    ]);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Security questions saved!',
              style: TextStyle(fontFamily: 'Ubuntu')),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }
}

// ─────────────────────────────────────────────
// ACADEMIC PROFILE EDITOR
// ─────────────────────────────────────────────
class AcademicProfileEditor extends StatefulWidget {
  final Map<String, dynamic> currentData;
  const AcademicProfileEditor({super.key, required this.currentData});

  @override
  State<AcademicProfileEditor> createState() => _AcademicProfileEditorState();
}

class _AcademicProfileEditorState extends State<AcademicProfileEditor> {
  late Map<String, dynamic> _editedData;

  final List<String> _educationLevels = [
    'High School',
    'Undergraduate',
    'Graduate',
    'Post Graduate',
  ];
  final List<String> _examTypes = [
    'TNPSC',
    'UPSC',
    'SSC',
    'Banking',
    'Railways',
    'Defence',
    'Other',
  ];
  final List<String> _targetYears = ['2025', '2026', '2027', '2028'];

  @override
  void initState() {
    super.initState();
    _editedData = Map<String, dynamic>.from(widget.currentData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(fontFamily: 'Ubuntu')),
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildDropdown('Education', _educationLevels, 'education'),
          SizedBox(height: 16),
          _buildDropdown('Exam Prep', _examTypes, 'examPrep'),
          SizedBox(height: 16),
          _buildDropdown('Target Year', _targetYears, 'targetYear'),
          SizedBox(height: 16),
          _buildTextField('Study Goal', 'studyGoal'),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _editedData),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2196F3),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save',
                style: TextStyle(
                    fontSize: 16, fontFamily: 'Ubuntu', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu',
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _editedData[key] == 'Not set' ? null : _editedData[key],
          decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          items: options
              .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, style: TextStyle(fontFamily: 'Ubuntu'))))
              .toList(),
          onChanged: (v) => setState(() => _editedData[key] = v ?? 'Not set'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu',
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 8),
        TextFormField(
          initialValue: _editedData[key] == 'Not set' ? '' : _editedData[key],
          decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          onChanged: (v) => _editedData[key] = v.isEmpty ? 'Not set' : v,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LOGIN / SIGNUP SCREEN
// ═══════════════════════════════════════════════════════════
class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebase = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null && mounted) {
      setState(() {
        _emailCtrl.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveOrClearEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailCtrl.text.trim());
    } else {
      await prefs.remove('saved_email');
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    await _saveOrClearEmail();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth
            .signInWithEmailAndPassword(
                email: _emailCtrl.text.trim(), password: _passwordCtrl.text)
            .timeout(Duration(seconds: 10));
      } else {
        final cred = await _auth
            .createUserWithEmailAndPassword(
                email: _emailCtrl.text.trim(), password: _passwordCtrl.text)
            .timeout(Duration(seconds: 10));

        // ✅ Set Auth displayName — do this first, it's fast
        await cred.user?.updateDisplayName(_nameCtrl.text.trim());

        // ✅ Create Firestore doc — wrapped in its own try/catch.
        // If Firestore is slow or rules block it, the user is STILL
        // authenticated. getUserProfile() will create the doc on next load.
        try {
          await _firebase.createUserProfile(
              name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim());
        } catch (firestoreErr) {
          debugPrint(
              '⚠️ Firestore profile creation failed (non-fatal): $firestoreErr');
        }
      }
      // ✅ Always pushReplacement to ProfileScreen after successful auth.
      // Works whether LoginSignupScreen is the root or pushed on top.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
          (route) => false, // clear entire back stack
        );
      }
    } on TimeoutException {
      if (mounted) setState(() => _isLoading = false);
      _showError('Connection timeout. Check your internet.');
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      // Show the REAL error in terminal and to user — no more mystery "Connection error"
      debugPrint('❌ _handleAuth unexpected error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password too weak (min 6 chars)';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Error: $code';
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: TextStyle(fontFamily: 'Ubuntu')),
        backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context))),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Icon(Icons.person, size: 80, color: Colors.white),
                          SizedBox(height: 24),
                          Text(_isLogin ? 'Welcome Back!' : 'Create Account',
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'Ubuntu')),
                          SizedBox(height: 32),
                          if (!_isLogin) ...[
                            _buildField(
                                controller: _nameCtrl,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (v) =>
                                    v!.isEmpty ? 'Enter name' : null),
                            SizedBox(height: 16),
                          ],
                          _buildField(
                              controller: _emailCtrl,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  !v!.contains('@') ? 'Invalid email' : null),
                          SizedBox(height: 16),
                          _buildField(
                              controller: _passwordCtrl,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscure: _obscurePassword,
                              toggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              validator: (v) =>
                                  v!.length < 6 ? 'Min 6 chars' : null),
                          SizedBox(height: 12),
                          if (_isLogin)
                            Row(children: [
                              Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) => setState(
                                      () => _rememberMe = val ?? false),
                                  activeColor: Colors.white,
                                  checkColor: Color(0xFF2196F3),
                                  side: BorderSide(
                                      color: Colors.white70, width: 2)),
                              Text('Remember Me',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Ubuntu',
                                      fontSize: 14)),
                            ]),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF2196F3),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      color: Color(0xFF2196F3), strokeWidth: 2)
                                  : Text(_isLogin ? 'Login' : 'Sign Up',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Ubuntu')),
                            ),
                          ),
                          SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                                _isLogin
                                    ? "Don't have an account? Sign Up"
                                    : 'Already have an account? Login',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Ubuntu')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Ubuntu'),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70),
                onPressed: toggleObscure)
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white30)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white30)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white, width: 2)),
        errorStyle: TextStyle(fontFamily: 'Ubuntu'),
      ),
    );
  }
}
