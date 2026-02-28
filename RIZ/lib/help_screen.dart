import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
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
                          onTap: () => _showTelegramDialog(),
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
            Text(
              'support@rizhub.com',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontFamily: 'Ubuntu',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Message sent! We\'ll get back to you soon ✅',
                        style: TextStyle(fontFamily: 'Ubuntu'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Send Message',
                  style: TextStyle(
                    fontFamily: 'Ubuntu',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTelegramDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Join Telegram',
          style: TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Join our Telegram community for live updates, discussion, and support.\n\nt.me/rizhub',
          style: TextStyle(fontFamily: 'Ubuntu'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontFamily: 'Ubuntu')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            child: const Text(
              'Open Telegram',
              style: TextStyle(fontFamily: 'Ubuntu', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

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
            const SizedBox(height: 16),
            TextField(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Bug report submitted! Thank you 🙏',
                        style: TextStyle(fontFamily: 'Ubuntu'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontFamily: 'Ubuntu',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
