import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bugReportController = TextEditingController();
  final TextEditingController _supportMessageController =
      TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _searchQuery = '';
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I start preparing for TNPSC?',
      'a':
          'Go to "Choose Your Category" on the home screen, tap TNPSC, and select your exam group. You\'ll find study links, exam dates, and resources tailored for TNPSC.',
    },
    {
      'q': 'Where can I find Current Affairs?',
      'a':
          'Tap "Current Affairs" in the Study Resources section on the home screen. It\'s updated regularly with the latest events relevant to government exams.',
    },
    {
      'q': 'What are Digital Flashcards?',
      'a':
          'Digital Flashcards use spaced repetition to help you memorize faster and retain longer. They\'re especially useful for GK, current affairs, and key facts.',
    },
    {
      'q': 'How do I access Previous Year Questions?',
      'a':
          'Tap "PYQ\'s" from the home screen or the drawer menu. You\'ll find past papers for UPSC, SSC, TNPSC, Banking, Railways, and more.',
    },
    {
      'q': 'What is Study Links / Study Vault?',
      'a':
          'Study Vault is your organized collection of curated study materials — PDFs, notes, videos, and external resources — all in one place.',
    },
    {
      'q': 'How do I enable notifications?',
      'a':
          'Go to Settings → Notifications → toggle on Push Notifications. You can also set daily study reminders and exam date alerts.',
    },
    {
      'q': 'How is my study streak calculated?',
      'a':
          'Your streak increases by 1 every consecutive day you open the app and access a resource. Missing a day resets the streak to 1.',
    },
    {
      'q': 'Can I use the app without an account?',
      'a':
          'Yes! You can browse all content without logging in. An account is only needed to save your profile, track progress, and sync data.',
    },
    {
      'q': 'How do I update my exam preferences?',
      'a':
          'Go to your Profile → tap the edit icon on Academic Profile → update your exam type, target year, and study goal.',
    },
    {
      'q': 'The app is slow — what should I do?',
      'a':
          'Try closing and reopening the app. Make sure you have a stable internet connection. If the issue persists, clear the cache from Settings → Clear Cache.',
    },
    {
      'q': 'How do I take a Mock Test?',
      'a':
          'Navigate to PYQ\'s from the home screen, select your exam (TNPSC, UPSC, SSC, etc.), and tap on any available mock test. The test will simulate real exam conditions with a timer and negative marking.',
    },
    {
      'q': 'Can I pause a mock test and resume later?',
      'a':
          'No, mock tests are designed to simulate real exam conditions. Once started, you must complete the test within the time limit. However, you can exit and lose your progress if needed.',
    },
    {
      'q': 'How do I change my app language?',
      'a':
          'Go to Settings → Study Preferences → App Language. Select from English, Tamil, Hindi, Telugu, Kannada, or Malayalam.',
    },
    {
      'q': 'How do I switch between Light and Dark theme?',
      'a':
          'Go to Settings → Appearance → Theme. Choose from System Default, Light, or Dark mode.',
    },
    {
      'q': 'What does "Clear Cache" do?',
      'a':
          'Clearing cache removes temporarily stored data to free up space and fix any loading issues. Your profile, study progress, and settings will not be affected.',
    },
    {
      'q': 'How do I reset my password?',
      'a':
          'On the login screen, tap "Forgot Password", enter your registered email, and follow the instructions sent to your inbox.',
    },
    {
      'q': 'Can I access the app offline?',
      'a':
          'Some features like viewing downloaded study materials work offline, but Current Affairs, Mock Tests, and syncing require an internet connection.',
    },
    {
      'q': 'How do I bookmark study materials?',
      'a':
          'Open any study link from the Study Vault, and tap the bookmark icon at the top. All bookmarked materials can be accessed from "My Bookmarks".',
    },
    {
      'q': 'What are the app\'s system requirements?',
      'a':
          'RIZ Learning Hub works on Android 5.0 (Lollipop) or later, and iOS 12.0 or later. A stable internet connection is recommended for best experience.',
    },
    {
      'q': 'How do I contact support for technical issues?',
      'a':
          'Tap "Email Us" from Quick Actions on this screen, or send an email to rizlearning0263@gmail.com. Our team responds within 24 hours.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs
        .where(
          (faq) =>
              faq['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              faq['a']!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bugReportController.dispose();
    _supportMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF2196F3),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Help & Support',
              style: TextStyle(
                color: Colors.black87,
                fontFamily: 'Ubuntu',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Hero
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How can we help?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Ubuntu',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Search FAQs or contact our team',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontFamily: 'Ubuntu',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _expandedIndex = null;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontFamily: 'Ubuntu',
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF2196F3),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick actions
              if (_searchQuery.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                      fontFamily: 'Ubuntu',
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.email_rounded,
                          label: 'Email Us',
                          color: Colors.blue,
                          onTap: () => _showContactDialog(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.telegram_rounded,
                          label: 'Telegram',
                          color: Colors.lightBlue,
                          onTap: () => _launchTelegram(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.bug_report_rounded,
                          label: 'Report Bug',
                          color: Colors.orange,
                          onTap: () => _showBugReportDialog(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // FAQs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'FREQUENTLY ASKED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                        fontFamily: 'Ubuntu',
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_filteredFaqs.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2196F3),
                          fontFamily: 'Ubuntu',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (_filteredFaqs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No results for "$_searchQuery"',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontFamily: 'Ubuntu',
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_filteredFaqs.length, (i) {
                  final faq = _filteredFaqs[i];
                  final isExpanded = _expandedIndex == i;
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? const Color(
                                    0xFF2196F3,
                                  ).withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.quiz_rounded,
                            color: isExpanded
                                ? const Color(0xFF2196F3)
                                : Colors.grey,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          faq['q']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Ubuntu',
                            color: isExpanded
                                ? const Color(0xFF2196F3)
                                : Colors.black87,
                          ),
                        ),
                        trailing: Icon(
                          isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: isExpanded
                              ? const Color(0xFF2196F3)
                              : Colors.grey,
                        ),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() => _expandedIndex = expanded ? i : null);
                        },
                        children: [
                          Text(
                            faq['a']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontFamily: 'Ubuntu',
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Still need help
              if (_searchQuery.isEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.headset_mic_rounded,
                        color: Color(0xFF2196F3),
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Still need help?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Ubuntu',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Our team usually responds within 24 hours',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontFamily: 'Ubuntu',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showContactDialog(),
                          icon: const Icon(
                            Icons.email_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Contact Support',
                            style: TextStyle(
                              fontFamily: 'Ubuntu',
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Contact Support with TWO options
  void _showContactDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Ubuntu',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'rizlearning0263@gmail.com',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontFamily: 'Ubuntu',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy,
                      size: 18, color: Color(0xFF2196F3)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(
                        const ClipboardData(text: 'rizlearning0263@gmail.com'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email copied to clipboard ✅',
                            style: TextStyle(fontFamily: 'Ubuntu')),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _supportMessageController,
              decoration: InputDecoration(
                hintText: 'Describe your issue...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Ubuntu',
                ),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 4,
              style: const TextStyle(fontFamily: 'Ubuntu'),
            ),
            const SizedBox(height: 12),

            // ✅ TWO BUTTONS: Submit to Firestore + Open Email App
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openEmailApp('Support Request'),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text(
                      'Open Email',
                      style: TextStyle(fontFamily: 'Ubuntu'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      side: const BorderSide(color: Color(0xFF2196F3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _submitSupportMessage(),
                    icon: const Icon(Icons.send_rounded,
                        size: 18, color: Colors.white),
                    label: const Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: 'Ubuntu',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FUNCTIONAL: Launch Telegram
  Future<void> _launchTelegram() async {
    final url = Uri.parse('https://t.me/rizhub0263');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open Telegram. Join at: t.me/rizhub0263',
                style: TextStyle(fontFamily: 'Ubuntu'),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Telegram. Visit: t.me/rizhub0263',
              style: TextStyle(fontFamily: 'Ubuntu'),
            ),
          ),
        );
      }
    }
  }

  // ✅ UPDATED: Bug Report Dialog with TWO options
  void _showBugReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Report a Bug 🐛',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Ubuntu',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'rizlearning0263@gmail.com',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontFamily: 'Ubuntu',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Colors.orange),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(
                        const ClipboardData(text: 'rizlearning0263@gmail.com'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email copied ✅',
                            style: TextStyle(fontFamily: 'Ubuntu')),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bugReportController,
              decoration: InputDecoration(
                hintText: 'What happened? What did you expect?',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Ubuntu',
                ),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 4,
              style: const TextStyle(fontFamily: 'Ubuntu'),
            ),
            const SizedBox(height: 12),

            // ✅ TWO BUTTONS: Submit to Firestore + Open Email App
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openEmailApp('Bug Report'),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text(
                      'Open Email',
                      style: TextStyle(fontFamily: 'Ubuntu'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _submitBugReport(),
                    icon: const Icon(Icons.send_rounded,
                        size: 18, color: Colors.white),
                    label: const Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: 'Ubuntu',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Open Email App with pre-filled message
  Future<void> _openEmailApp(String type) async {
    String body = '';

    if (type == 'Bug Report') {
      body = _bugReportController.text.trim();
    } else {
      body = _supportMessageController.text.trim();
    }

    if (body.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please write a message first',
              style: TextStyle(fontFamily: 'Ubuntu'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // mail id, to not spam it tho...
    final String emailAddress = 'rizlearning0263@gmail.com';
    final String subject = Uri.encodeComponent('RIZ Learning Hub - $type');
    final String emailBody = Uri.encodeComponent(body);

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      query: 'subject=$subject&body=$emailBody',
    );

    try {
      final bool canLaunch = await canLaunchUrl(emailUri);

      if (canLaunch) {
        final bool launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );

        if (launched && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email app opened. Please send the email ✅',
                style: TextStyle(fontFamily: 'Ubuntu'),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Could not open email app. Email: rizlearning0263@gmail.com',
                style: TextStyle(fontFamily: 'Ubuntu'),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Copy',
                textColor: Colors.white,
                onPressed: () {
                  Clipboard.setData(
                      const ClipboardData(text: 'rizlearning0263@gmail.com'));
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not open email app. Email: rizlearning0263@gmail.com',
              style: TextStyle(fontFamily: 'Ubuntu'),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Copy',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(
                    const ClipboardData(text: 'rizlearning0263@gmail.com'));
              },
            ),
          ),
        );
      }
    }
  }

  // ✅ UPDATED: Submit Support Message (Firestore only)
  Future<void> _submitSupportMessage() async {
    if (_supportMessageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your issue',
              style: TextStyle(fontFamily: 'Ubuntu')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2196F3)),
        ),
      );

      // Get user info
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final userEmail = user?.email ?? 'No email';

      // Save to Firestore
      await _db.collection('supportMessages').add({
        'userId': userId,
        'userEmail': userEmail,
        'message': _supportMessageController.text.trim(),
        'type': 'support',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'resolved': false,
      });

      _supportMessageController.clear();

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close bottom sheet

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message submitted successfully! We\'ll respond soon ✅',
              style: TextStyle(fontFamily: 'Ubuntu'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting support message: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error submitting. Please use "Open Email" button instead.',
              style: TextStyle(fontFamily: 'Ubuntu'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ UPDATED: Submit Bug Report (Firestore only)
  Future<void> _submitBugReport() async {
    if (_bugReportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the bug',
              style: TextStyle(fontFamily: 'Ubuntu')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      // Get user info
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final userEmail = user?.email ?? 'No email';

      // Save to Firestore
      await _db.collection('bugReports').add({
        'userId': userId,
        'userEmail': userEmail,
        'description': _bugReportController.text.trim(),
        'status': 'open',
        'priority': 'medium',
        'createdAt': FieldValue.serverTimestamp(),
        'resolved': false,
        'device': 'mobile',
      });

      _bugReportController.clear();

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close bottom sheet

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bug report submitted! Thank you for helping us improve 🙏',
              style: TextStyle(fontFamily: 'Ubuntu'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting bug report: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error submitting. Please use "Open Email" button instead.',
              style: TextStyle(fontFamily: 'Ubuntu'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu',
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
