import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'firebase_service.dart';
import 'profile_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart'; // ✅ imports appThemeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _firebase = FirebaseService();
  final ProfileService _profileService = ProfileService();

  bool _notificationsEnabled = false;
  bool _dailyReminder = false;
  bool _examAlerts = true;
  bool _currentAffairsAlert = true;
  String _reminderTime = '08:00 AM';
  String _selectedTheme = 'System Default';
  bool _hapticFeedback = true;
  String _defaultCategory = 'Not set';
  String _language = 'en';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final notifEnabled =
          await NotificationService().areNotificationsEnabled();
      final settings = await _firebase.getSettings();
      if (mounted) {
        setState(() {
          _notificationsEnabled = notifEnabled;
          _dailyReminder = settings['dailyReminder'] ?? false;
          _examAlerts = settings['examAlerts'] ?? true;
          _currentAffairsAlert = settings['currentAffairsAlert'] ?? true;
          _reminderTime = settings['reminderTime'] ?? '08:00 AM';
          _selectedTheme = settings['theme'] ?? 'System Default';
          _hapticFeedback = settings['hapticFeedback'] ?? true;
          _defaultCategory = settings['defaultCategory'] ?? 'Not set';
          _language = settings['language'] ?? 'en';
          _loading = false;
        });

        // ✅ Apply saved theme immediately on screen load
        _applyTheme(_selectedTheme);
      }
    } catch (e) {
      debugPrint('❌ _loadSettings error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ THE FIX: updates appThemeNotifier so MaterialApp rebuilds immediately
  void _applyTheme(String theme) {
    switch (theme) {
      case 'Light':
        appThemeNotifier.value = ThemeMode.light;
        break;
      case 'Dark':
        appThemeNotifier.value = ThemeMode.dark;
        break;
      default:
        appThemeNotifier.value = ThemeMode.light; // default Light
    }
    // ✅ Also save to SharedPreferences so main.dart loads it on cold restart
    SharedPreferences.getInstance().then((p) => p.setString('theme', theme));
  }

  Future<void> _save(String key, dynamic value) async {
    setState(() => _saving = true);
    try {
      await _firebase.updateSetting(key, value);
      _profileService.clearCache();
    } catch (e) {
      debugPrint('❌ _save error for $key: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save setting: $e',
              style: TextStyle(
                  fontFamily: 'Ubuntu',
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Theme.of(context).colorScheme.onSurface)),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF2196F3), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Text('Settings',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'Ubuntu',
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
                Spacer(),
                if (_saving)
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF2196F3))),
                if (!_saving)
                  Icon(Icons.cloud_done_rounded,
                      color: Color(0xFF2196F3), size: 20),
              ],
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2196F3))))
          else
            SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: 8),

                // ── ACCOUNT ──────────────────────────────
                _sectionHeader('Account'),
                _card([
                  _navTile(
                    icon: Icons.person_outline_rounded,
                    iconColor: Color(0xFF2196F3),
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () => _editProfile(),
                  ),
                ]),

                // ── NOTIFICATIONS ──────────────────────────────
                _sectionHeader('Notifications'),
                _card([
                  _switchTile(
                    icon: Icons.notifications_rounded,
                    iconColor: Color(0xFF2196F3),
                    title: 'Push Notifications',
                    subtitle: 'Receive exam alerts and study reminders',
                    value: _notificationsEnabled,
                    onChanged: (val) async {
                      if (val) {
                        final granted =
                            await NotificationService().requestPermission();
                        setState(() => _notificationsEnabled = granted);
                        await _save('notificationsEnabled', granted);
                        if (!granted && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Permission denied',
                                  style: TextStyle(fontFamily: 'Ubuntu')),
                              backgroundColor: Colors.red));
                        }
                      } else {
                        await NotificationService().disableNotifications();
                        setState(() => _notificationsEnabled = false);
                        await _save('notificationsEnabled', false);
                      }
                    },
                  ),
                  if (_notificationsEnabled) ...[
                    _divider(),
                    _switchTile(
                      icon: Icons.alarm_rounded,
                      iconColor: Colors.orange,
                      title: 'Daily Study Reminder',
                      subtitle: 'Remind me to study every day',
                      value: _dailyReminder,
                      onChanged: (val) async {
                        setState(() => _dailyReminder = val);
                        await _save('dailyReminder', val);
                        if (_hapticFeedback) HapticFeedback.lightImpact();
                      },
                    ),
                    if (_dailyReminder) ...[
                      _divider(),
                      _navTile(
                        icon: Icons.schedule_rounded,
                        iconColor: Colors.purple,
                        title: 'Reminder Time',
                        subtitle: _reminderTime,
                        onTap: () async {
                          final time = await showTimePicker(
                              context: context, initialTime: TimeOfDay.now());
                          if (time != null && mounted) {
                            final formatted = time.format(context);
                            setState(() => _reminderTime = formatted);
                            await _save('reminderTime', formatted);
                          }
                        },
                      ),
                    ],
                    _divider(),
                    _switchTile(
                      icon: Icons.event_rounded,
                      iconColor: Colors.green,
                      title: 'Exam Date Alerts',
                      subtitle: 'Notified before upcoming exams',
                      value: _examAlerts,
                      onChanged: (val) async {
                        setState(() => _examAlerts = val);
                        await _save('examAlerts', val);
                      },
                    ),
                    _divider(),
                    _switchTile(
                      icon: Icons.article_rounded,
                      iconColor: Colors.teal,
                      title: 'Current Affairs',
                      subtitle: 'Daily current affairs digest',
                      value: _currentAffairsAlert,
                      onChanged: (val) async {
                        setState(() => _currentAffairsAlert = val);
                        await _save('currentAffairsAlert', val);
                      },
                    ),
                  ],
                ]),

                // ── APPEARANCE ─────────────────────────────────
                _sectionHeader('Appearance'),
                _card([
                  _navTile(
                    icon: Icons.dark_mode_rounded,
                    iconColor: Colors.indigo,
                    title: 'Theme',
                    subtitle: _selectedTheme,
                    onTap: () => _showThemePicker(),
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.vibration_rounded,
                    iconColor: Colors.deepOrange,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrate on interactions',
                    value: _hapticFeedback,
                    onChanged: (val) async {
                      setState(() => _hapticFeedback = val);
                      await _save('hapticFeedback', val);
                      if (val) HapticFeedback.mediumImpact();
                    },
                  ),
                ]),

                // ── STUDY PREFERENCES ──────────────────────────
                _sectionHeader('Study Preferences'),
                _card([
                  _navTile(
                    icon: Icons.category_rounded,
                    iconColor: Color(0xFF2196F3),
                    title: 'Default Category',
                    subtitle: _defaultCategory,
                    onTap: () => _showCategoryPicker(),
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.language_rounded,
                    iconColor: Colors.green,
                    title: 'App Language',
                    subtitle: _getLanguageDisplay(_language),
                    onTap: () => _showLanguagePicker(),
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.storage_rounded,
                    iconColor: Colors.orange,
                    title: 'Clear Cache',
                    subtitle: 'Refresh locally stored data',
                    onTap: () => _clearCache(),
                  ),
                ]),

                // ── ABOUT ──────────────────────────────────────
                _sectionHeader('About'),
                _card([
                  _navTile(
                      icon: Icons.info_rounded,
                      iconColor: Colors.blue,
                      title: 'App Version',
                      subtitle: '1.0.0 (Build 1)',
                      onTap: () => _showAboutDialog()),
                  _divider(),
                  _navTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: Colors.teal,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy policy',
                      onTap: () => _launchPrivacyPolicy()),
                  _divider(),
                  _navTile(
                      icon: Icons.description_rounded,
                      iconColor: Colors.indigo,
                      title: 'Terms of Service',
                      subtitle: 'Read our terms',
                      onTap: () => _launchTermsOfService()),
                  _divider(),
                  _navTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: Colors.purple,
                      title: 'Help & Support',
                      subtitle: 'Get help or report issues',
                      onTap: () => _launchSupport()),
                ]),

                SizedBox(height: 40),
              ]),
            ),
        ],
      ),
    );
  }

  // ─── UI Helpers ──────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodySmall?.color ??
                  Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'Ubuntu',
              letterSpacing: 0.8)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(icon, iconColor),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Ubuntu',
              color: Theme.of(context).textTheme.bodyLarge?.color ??
                  Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color ??
                  Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'Ubuntu')),
      trailing: Switch.adaptive(
          value: value, onChanged: onChanged, activeColor: Color(0xFF2196F3)),
    );
  }

  Widget _navTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(icon, iconColor),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Ubuntu',
              color: titleColor ??
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color ??
                  Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'Ubuntu')),
      trailing: onTap != null
          ? Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.black38)
          : null,
      onTap: onTap,
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _divider() =>
      Divider(height: 1, indent: 68, endIndent: 16, color: Colors.grey[100]);

  // ─── Theme Picker ────────────────────────────────────────

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 16),
          Text('Choose Theme',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Ubuntu',
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Theme.of(context).colorScheme.onSurface)),
          SizedBox(height: 8),
          // Theme options with icons so it's clear what each does
          _themeOption(ctx, 'System Default', Icons.brightness_auto_rounded,
              Colors.blueGrey),
          _themeOption(ctx, 'Light', Icons.light_mode_rounded, Colors.orange),
          _themeOption(ctx, 'Dark', Icons.dark_mode_rounded, Colors.indigo),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _themeOption(
      BuildContext ctx, String theme, IconData icon, Color color) {
    final isSelected = _selectedTheme == theme;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(theme,
          style: TextStyle(
              fontFamily: 'Ubuntu',
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: Color(0xFF2196F3))
          : null,
      onTap: () async {
        // 1. Update UI state
        setState(() => _selectedTheme = theme);
        // 2. Apply theme IMMEDIATELY — this is the fix
        _applyTheme(theme);
        // 3. Close sheet
        Navigator.pop(ctx);
        // 4. Save to Firestore in background
        await _save('theme', theme);
        // 5. Confirm to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Theme set to $theme ✅',
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Theme.of(context).colorScheme.onSurface)),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ));
        }
      },
    );
  }

  // ─── Other Pickers ───────────────────────────────────────

  void _showCategoryPicker() {
    const categories = [
      'TNPSC',
      'UPSC',
      'SSC',
      'Banking',
      'Railways',
      'Defence'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 16),
          Text('Default Category',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Ubuntu',
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Theme.of(context).colorScheme.onSurface)),
          SizedBox(height: 8),
          ...categories.map((cat) => ListTile(
                title: Text(cat,
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        color: Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).colorScheme.onSurface)),
                trailing: _defaultCategory == cat
                    ? Icon(Icons.check_rounded, color: Color(0xFF2196F3))
                    : null,
                onTap: () async {
                  setState(() => _defaultCategory = cat);
                  Navigator.pop(ctx);
                  await _save('defaultCategory', cat);
                },
              )),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    const languages = {
      'en': 'English',
      'ta': 'தமிழ் (Tamil)',
      'hi': 'हिंदी (Hindi)',
      'te': 'తెలుగు (Telugu)',
      'kn': 'ಕನ್ನಡ (Kannada)',
      'ml': 'മലയാളം (Malayalam)',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 16),
          Text('App Language',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Ubuntu',
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Theme.of(context).colorScheme.onSurface)),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Choose your preferred language',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey, fontFamily: 'Ubuntu')),
          ),
          SizedBox(height: 12),
          ...languages.entries.map((entry) => ListTile(
                title: Text(entry.value,
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        color: Theme.of(context).textTheme.bodyLarge?.color ??
                            Theme.of(context).colorScheme.onSurface)),
                trailing: _language == entry.key
                    ? Icon(Icons.check_rounded, color: Color(0xFF2196F3))
                    : null,
                onTap: () async {
                  setState(() => _language = entry.key);
                  Navigator.pop(ctx);
                  await _save('language', entry.key);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✅ Language set to ${entry.value}',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Theme.of(context).colorScheme.onSurface)),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ));
                  }
                },
              )),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('RIZ',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 2,
                      fontFamily: 'Ubuntu')),
            ),
            SizedBox(width: 12),
            Text('Learning Hub', style: TextStyle(fontFamily: 'Ubuntu')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0 (Build 1)',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color ??
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: 'Ubuntu')),
            SizedBox(height: 12),
            Text(
              'Empowering aspirants to achieve their dreams through comprehensive exam preparation.',
              style: TextStyle(fontFamily: 'Ubuntu', fontSize: 13),
            ),
            SizedBox(height: 16),
            Text('Made with ❤️ for every achiever',
                style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Ubuntu',
                    fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontFamily: 'Ubuntu')),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    final url = Uri.parse('https://rizlearninghub.com/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Privacy Policy coming soon',
                style: TextStyle(fontFamily: 'Ubuntu'))));
      }
    }
  }

  Future<void> _launchTermsOfService() async {
    final url = Uri.parse('https://rizlearninghub.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Terms of Service coming soon',
                style: TextStyle(fontFamily: 'Ubuntu'))));
      }
    }
  }

  Future<void> _launchSupport() async {
    final url =
        Uri.parse('mailto:support@rizlearninghub.com?subject=Support Request');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Email: support@rizlearninghub.com',
                style: TextStyle(fontFamily: 'Ubuntu')),
            duration: Duration(seconds: 3)));
      }
    }
  }

  Future<void> _clearCache() async {
    _profileService.clearCache();
    await _loadSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Cache cleared ✅', style: TextStyle(fontFamily: 'Ubuntu')),
          backgroundColor: Colors.green));
    }
  }

  Future<void> _editProfile() async {
    final profile = await _profileService.getUserProfile();
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EditProfileScreen(currentData: profile ?? {})),
    );

    if (result != null) {
      await _firebase.updateProfile(result);
      _profileService.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Profile updated!',
                style: TextStyle(fontFamily: 'Ubuntu')),
            backgroundColor: Colors.green));
      }
    }
  }

  String _getLanguageDisplay(String lang) {
    const langMap = {
      'en': 'English',
      'ta': 'தமிழ் (Tamil)',
      'hi': 'हिंदी (Hindi)',
      'te': 'తెలుగు (Telugu)',
      'kn': 'ಕನ್ನಡ (Kannada)',
      'ml': 'മലയാളം (Malayalam)',
    };
    return langMap[lang] ?? 'English';
  }
}

// ═══════════════════════════════════════════════════════════
// EDIT PROFILE SCREEN
// ═══════════════════════════════════════════════════════════

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentData;
  const EditProfileScreen({super.key, required this.currentData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
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
    'State PSC',
    'Other',
  ];
  final List<String> _targetYears = ['2025', '2026', '2027', '2028', '2029'];

  @override
  void initState() {
    super.initState();
    _editedData = Map<String, dynamic>.from(widget.currentData);
    _nameController = TextEditingController(text: _editedData['name'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Edit Profile',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildTextField(
            label: 'Full Name',
            icon: Icons.person_outline,
            controller: _nameController,
            onChanged: (val) => _editedData['name'] = val,
          ),
          SizedBox(height: 16),
          _buildDropdown('Education', _educationLevels, 'education'),
          SizedBox(height: 16),
          _buildDropdown('Exam Preparation', _examTypes, 'examPrep'),
          SizedBox(height: 16),
          _buildDropdown('Target Year', _targetYears, 'targetYear'),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Study Goal',
            icon: Icons.flag_outlined,
            initialValue: _editedData['studyGoal'] == 'Not set'
                ? ''
                : _editedData['studyGoal'],
            onChanged: (val) =>
                _editedData['studyGoal'] = val.isEmpty ? 'Not set' : val,
            maxLines: 2,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Sync name controller value before popping
              _editedData['name'] = _nameController.text.trim();
              Navigator.pop(context, _editedData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2196F3),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save Changes',
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Ubuntu',
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    String? initialValue,
    Function(String)? onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu',
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          maxLines: maxLines,
          style: TextStyle(
              fontFamily: 'Ubuntu',
              color: Theme.of(context).textTheme.bodyLarge?.color ??
                  Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF2196F3), size: 20),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu',
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _editedData[key] == 'Not set' ? null : _editedData[key],
              isExpanded: true,
              hint: Text('Select $label',
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontFamily: 'Ubuntu')),
              style: TextStyle(
                  fontFamily: 'Ubuntu',
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize: 15),
              items: options
                  .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o, style: TextStyle(fontFamily: 'Ubuntu'))))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _editedData[key] = v ?? 'Not set'),
            ),
          ),
        ),
      ],
    );
  }
}
