import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'category_detail_screen.dart';
import 'current_affairs_screen.dart';
import 'quantitative_aptitude_screen.dart';
import 'general_knowledge_screen.dart';
import 'feature_screens.dart';

// ─────────────────────────────────────────────
// Navigation helper — maps category name → Firestore id + color
// No more CategoryBackend. Everything goes through Firestore.
// ─────────────────────────────────────────────
class _CategoryNav {
  static const _map = {
    'TNPSC': {'id': 'tnpsc', 'icon': '🏛️', 'color': 0xFF8B7355},
    'UPSC': {'id': 'upsc', 'icon': '🇮🇳', 'color': 0xFF1565C0},
    'SSC': {'id': 'ssc', 'icon': '📝', 'color': 0xFF6A1B9A},
    'Banking': {'id': 'banking', 'icon': '🏦', 'color': 0xFF1B5E20},
    'Railways': {'id': 'railways', 'icon': '🚂', 'color': 0xFF00695C},
    'Defence': {'id': 'defence', 'icon': '⚔️', 'color': 0xFFB71C1C},
  };

  // Job role → parent category mapping
  static const _jobRoleParent = {
    'Group 1': 'TNPSC',
    'Group 2': 'TNPSC',
    'Group 4 / VAO': 'TNPSC',
    'Group 4': 'TNPSC',
    'Civil Services': 'UPSC',
    'Civil Services (IAS/IPS)': 'UPSC',
    'CAPF AC': 'UPSC',
    'CGL': 'SSC',
    'CHSL': 'SSC',
    'MTS': 'SSC',
    'IBPS PO': 'Banking',
    'SBI PO': 'Banking',
    'IBPS Clerk': 'Banking',
    'RRB NTPC': 'Railways',
    'RRC Group D': 'Railways',
    'NDA': 'Defence',
    'CDS': 'Defence',
    'AFCAT': 'Defence',
  };

  static void navigate(BuildContext context, String nameOrRole) {
    // Resolve job role to parent category if needed
    final categoryName = _jobRoleParent[nameOrRole] ?? nameOrRole;
    final info = _map[categoryName];
    if (info == null) return;

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(
            categoryId: info['id'] as String,
            categoryName: categoryName,
            categoryIcon: info['icon'] as String,
            categoryColor: Color(info['color'] as int),
          ),
        ));
  }
}

// ─────────────────────────────────────────────
// Search Entry Point
// ─────────────────────────────────────────────
class ExamSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search exams, topics, resources...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
            color: Colors.black45, fontFamily: 'Ubuntu', fontSize: 16),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            color: Colors.black87, fontSize: 16, fontFamily: 'Ubuntu'),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.black54),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _SearchResults(query: query);

  @override
  Widget buildSuggestions(BuildContext context) =>
      query.isEmpty ? const _SearchHome() : _SearchResults(query: query);
}

// ─────────────────────────────────────────────
// Search Home — shown when search bar is empty
// ─────────────────────────────────────────────
class _SearchHome extends StatelessWidget {
  const _SearchHome();

  static const _categories = [
    {'label': 'TNPSC', 'icon': '🏛️', 'color': Color(0xFF8B7355)},
    {'label': 'UPSC', 'icon': '🇮🇳', 'color': Color(0xFF1565C0)},
    {'label': 'SSC', 'icon': '📝', 'color': Color(0xFF6A1B9A)},
    {'label': 'Banking', 'icon': '🏦', 'color': Color(0xFF1B5E20)},
    {'label': 'Railways', 'icon': '🚂', 'color': Color(0xFF00695C)},
    {'label': 'Defence', 'icon': '⚔️', 'color': Color(0xFFB71C1C)},
  ];

  static const _quickAccess = [
    {
      'label': 'Current Affairs',
      'icon': Icons.article_rounded,
      'color': Color(0xFF2196F3)
    },
    {
      'label': 'Quantitative Aptitude',
      'icon': Icons.calculate_rounded,
      'color': Color(0xFF7B1FA2)
    },
    {
      'label': 'General Knowledge',
      'icon': Icons.public_rounded,
      'color': Color(0xFFE65100)
    },
    {
      'label': 'Digital Flashcards',
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFF7B1FA2)
    },
    {
      'label': "PYQ's",
      'icon': Icons.history_edu_rounded,
      'color': Color(0xFF2196F3)
    },
    {
      'label': 'Study Links',
      'icon': Icons.folder_special_rounded,
      'color': Color(0xFFE65100)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Exam Categories',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Ubuntu',
                color: Colors.black87)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((cat) {
            final color = cat['color'] as Color;
            return GestureDetector(
              onTap: () =>
                  _CategoryNav.navigate(context, cat['label'] as String),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['icon'] as String,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(cat['label'] as String,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Ubuntu',
                            color: color)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        const Text('Quick Access',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Ubuntu',
                color: Colors.black87)),
        const SizedBox(height: 12),
        ..._quickAccess.map((item) {
          final color = item['color'] as Color;
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item['icon'] as IconData, color: color, size: 22),
            ),
            title: Text(item['label'] as String,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Ubuntu',
                    color: Colors.black87)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.black38),
            onTap: () => _navigateToScreen(context, item['label'] as String),
          );
        }),
      ],
    );
  }

  void _navigateToScreen(BuildContext context, String label) {
    Widget? screen;
    switch (label) {
      case 'Current Affairs':
        screen = const CurrentAffairsScreen();
        break;
      case 'Quantitative Aptitude':
        screen = const QuantitativeAptitudeScreen();
        break;
      case 'General Knowledge':
        screen = const GeneralKnowledgeScreen();
        break;
      case 'Digital Flashcards':
        screen = const DigitalFlashcardsScreen();
        break;
      case "PYQ's":
        screen = const PYQsScreen();
        break;
      case 'Study Links':
        screen = const StudyVaultScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }
}

// ─────────────────────────────────────────────
// Search Results
// ─────────────────────────────────────────────
class _SearchResults extends StatelessWidget {
  final String query;
  const _SearchResults({required this.query});

  static final List<_SearchItem> _allItems = [
    // ── Main categories ──
    _SearchItem(
        title: 'TNPSC',
        subtitle: 'Tamil Nadu Public Service Commission',
        category: 'Exam Category',
        icon: '🏛️',
        type: _Type.category),
    _SearchItem(
        title: 'UPSC',
        subtitle: 'Union Public Service Commission',
        category: 'Exam Category',
        icon: '🇮🇳',
        type: _Type.category),
    _SearchItem(
        title: 'SSC',
        subtitle: 'Staff Selection Commission',
        category: 'Exam Category',
        icon: '📝',
        type: _Type.category),
    _SearchItem(
        title: 'Banking',
        subtitle: 'IBPS PO, SBI PO, Clerk, RBI',
        category: 'Exam Category',
        icon: '🏦',
        type: _Type.category),
    _SearchItem(
        title: 'Railways',
        subtitle: 'RRB NTPC, Group D',
        category: 'Exam Category',
        icon: '🚂',
        type: _Type.category),
    _SearchItem(
        title: 'Defence',
        subtitle: 'NDA, CDS, AFCAT',
        category: 'Exam Category',
        icon: '⚔️',
        type: _Type.category),
    // ── TNPSC job roles ──
    _SearchItem(
        title: 'Group 1',
        subtitle: 'Deputy Collector, DSP, Joint Registrar',
        category: 'TNPSC',
        icon: '🏛️',
        type: _Type.category),
    _SearchItem(
        title: 'Group 2',
        subtitle: 'Sub-Registrar, Revenue Inspector',
        category: 'TNPSC',
        icon: '🏛️',
        type: _Type.category),
    _SearchItem(
        title: 'Group 4 / VAO',
        subtitle: 'Village Administrative Officer',
        category: 'TNPSC',
        icon: '🏛️',
        type: _Type.category),
    // ── UPSC job roles ──
    _SearchItem(
        title: 'Civil Services (IAS/IPS)',
        subtitle: 'IAS, IPS, IFS — 24 Central Services',
        category: 'UPSC',
        icon: '🇮🇳',
        type: _Type.category),
    _SearchItem(
        title: 'CAPF AC',
        subtitle: 'BSF, CRPF, CISF, ITBP, SSB Officer',
        category: 'UPSC',
        icon: '🇮🇳',
        type: _Type.category),
    // ── SSC job roles ──
    _SearchItem(
        title: 'CGL',
        subtitle: 'Income Tax Inspector, Auditor, CSS',
        category: 'SSC',
        icon: '📝',
        type: _Type.category),
    _SearchItem(
        title: 'CHSL',
        subtitle: 'LDC, JSA, Postal Assistant, DEO',
        category: 'SSC',
        icon: '📝',
        type: _Type.category),
    _SearchItem(
        title: 'MTS',
        subtitle: 'Multi Tasking Staff, Havaldar',
        category: 'SSC',
        icon: '📝',
        type: _Type.category),
    // ── Banking job roles ──
    _SearchItem(
        title: 'IBPS PO',
        subtitle: 'Probationary Officer — 19 Banks',
        category: 'Banking',
        icon: '🏦',
        type: _Type.category),
    _SearchItem(
        title: 'SBI PO',
        subtitle: 'State Bank of India PO',
        category: 'Banking',
        icon: '🏦',
        type: _Type.category),
    _SearchItem(
        title: 'IBPS Clerk',
        subtitle: 'Junior Associate — 19 Banks',
        category: 'Banking',
        icon: '🏦',
        type: _Type.category),
    // ── Railways job roles ──
    _SearchItem(
        title: 'RRB NTPC',
        subtitle: 'Station Master, Guard, ASM, Clerk',
        category: 'Railways',
        icon: '🚂',
        type: _Type.category),
    _SearchItem(
        title: 'RRC Group D',
        subtitle: 'Track Maintainer, Helper, Porter',
        category: 'Railways',
        icon: '🚂',
        type: _Type.category),
    // ── Defence job roles ──
    _SearchItem(
        title: 'NDA',
        subtitle: 'Army, Navy, Air Force after 12th',
        category: 'Defence',
        icon: '⚔️',
        type: _Type.category),
    _SearchItem(
        title: 'CDS',
        subtitle: 'IMA, OTA, Naval Academy, Air Force',
        category: 'Defence',
        icon: '⚔️',
        type: _Type.category),
    _SearchItem(
        title: 'AFCAT',
        subtitle: 'Flying, Technical & Ground Duty (AF)',
        category: 'Defence',
        icon: '⚔️',
        type: _Type.category),
    // ── Study resources ──
    _SearchItem(
        title: 'Current Affairs',
        subtitle: 'Updated daily with latest events',
        category: 'Study Resource',
        iconData: Icons.article_rounded,
        color: Color(0xFF2196F3),
        type: _Type.resource),
    _SearchItem(
        title: 'Quantitative Aptitude',
        subtitle: 'Complete guide with shortcuts',
        category: 'Study Resource',
        iconData: Icons.calculate_rounded,
        color: Color(0xFF7B1FA2),
        type: _Type.resource),
    _SearchItem(
        title: 'General Knowledge',
        subtitle: 'Comprehensive GK database',
        category: 'Study Resource',
        iconData: Icons.public_rounded,
        color: Color(0xFFE65100),
        type: _Type.resource),
    // ── Features ──
    _SearchItem(
        title: 'Digital Flashcards',
        subtitle: 'Smart adaptive learning',
        category: 'Feature',
        iconData: Icons.auto_awesome_rounded,
        color: Color(0xFF7B1FA2),
        type: _Type.feature),
    _SearchItem(
        title: "PYQ's",
        subtitle: 'Previous Year Questions',
        category: 'Feature',
        iconData: Icons.history_edu_rounded,
        color: Color(0xFF2196F3),
        type: _Type.feature),
    _SearchItem(
        title: 'Study Links',
        subtitle: 'Organised study materials vault',
        category: 'Feature',
        iconData: Icons.folder_special_rounded,
        color: Color(0xFFE65100),
        type: _Type.feature),
    // ── Topics ──
    _SearchItem(
        title: 'General Studies',
        subtitle: 'History, Geography, Polity, Economy',
        category: 'Subject',
        iconData: Icons.menu_book_rounded,
        color: Color(0xFF388E3C),
        type: _Type.topic),
    _SearchItem(
        title: 'Aptitude & Reasoning',
        subtitle: 'Quant, logical reasoning, DI',
        category: 'Subject',
        iconData: Icons.psychology_rounded,
        color: Color(0xFF388E3C),
        type: _Type.topic),
    _SearchItem(
        title: 'English Language',
        subtitle: 'Grammar, comprehension, vocabulary',
        category: 'Subject',
        iconData: Icons.translate_rounded,
        color: Color(0xFF388E3C),
        type: _Type.topic),
    _SearchItem(
        title: 'Preliminary Exam',
        subtitle: 'Objective type — first stage',
        category: 'Exam Stage',
        iconData: Icons.assignment_rounded,
        color: Color(0xFF1976D2),
        type: _Type.topic),
    _SearchItem(
        title: 'Main Examination',
        subtitle: 'Descriptive — advanced stage',
        category: 'Exam Stage',
        iconData: Icons.assignment_rounded,
        color: Color(0xFF1976D2),
        type: _Type.topic),
    _SearchItem(
        title: 'Interview',
        subtitle: 'Final personality test stage',
        category: 'Exam Stage',
        iconData: Icons.record_voice_over_rounded,
        color: Color(0xFF1976D2),
        type: _Type.topic),
  ];

  List<_SearchItem> get _filtered {
    final q = query.toLowerCase();
    return _allItems
        .where((i) =>
            i.title.toLowerCase().contains(q) ||
            i.subtitle.toLowerCase().contains(q) ||
            i.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    if (results.isEmpty) return _emptyState();

    final byType = {
      'Exam Categories':
          results.where((r) => r.type == _Type.category).toList(),
      'Study Resources':
          results.where((r) => r.type == _Type.resource).toList(),
      'Features': results.where((r) => r.type == _Type.feature).toList(),
      'Topics & Subjects': results.where((r) => r.type == _Type.topic).toList(),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in byType.entries)
          if (entry.value.isNotEmpty) ...[
            _SectionHeader(title: entry.key, count: entry.value.length),
            ...entry.value.map((item) => _ResultTile(item: item)),
          ],
      ],
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No results for "$query"',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                    fontFamily: 'Ubuntu')),
            const SizedBox(height: 8),
            Text('Try: TNPSC, UPSC, SSC, Banking, Current Affairs...',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    fontFamily: 'Ubuntu')),
          ],
        ),
      );
}

// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Ubuntu',
                color: Colors.black45,
                letterSpacing: 1.0)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2196F3),
                  fontFamily: 'Ubuntu')),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
class _ResultTile extends StatelessWidget {
  final _SearchItem item;
  const _ResultTile({required this.item});

  static const _catColors = {
    'TNPSC': Color(0xFF8B7355),
    'UPSC': Color(0xFF1565C0),
    'SSC': Color(0xFF6A1B9A),
    'Banking': Color(0xFF1B5E20),
    'Railways': Color(0xFF00695C),
    'Defence': Color(0xFFB71C1C),
  };

  Color get _color =>
      item.color ?? _catColors[item.category] ?? const Color(0xFF2196F3);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: item.icon != null
              ? Center(
                  child: Text(item.icon!, style: const TextStyle(fontSize: 22)))
              : Icon(item.iconData, color: _color, size: 22),
        ),
        title: Text(item.title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu',
                color: Colors.black87)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(item.subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Ubuntu')),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(item.category,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _color,
                      fontFamily: 'Ubuntu')),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey[400]),
        onTap: () {
          HapticFeedback.lightImpact();
          _navigate(context);
        },
      ),
    );
  }

  void _navigate(BuildContext context) {
    // ── Category / job role → CategoryDetailScreen via Firestore ──
    if (item.type == _Type.category) {
      _CategoryNav.navigate(context, item.title);
      return;
    }
    // ── Resources / features → their own screen ──
    Widget? screen;
    switch (item.title) {
      case 'Current Affairs':
        screen = const CurrentAffairsScreen();
        break;
      case 'Quantitative Aptitude':
        screen = const QuantitativeAptitudeScreen();
        break;
      case 'General Knowledge':
        screen = const GeneralKnowledgeScreen();
        break;
      case 'Digital Flashcards':
        screen = const DigitalFlashcardsScreen();
        break;
      case "PYQ's":
        screen = const PYQsScreen();
        break;
      case 'Study Links':
        screen = const StudyVaultScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }
}

// ─────────────────────────────────────────────
enum _Type { category, resource, feature, topic }

class _SearchItem {
  final String title;
  final String subtitle;
  final String category;
  final String? icon;
  final IconData? iconData;
  final Color? color;
  final _Type type;

  const _SearchItem({
    required this.title,
    required this.subtitle,
    required this.category,
    this.icon,
    this.iconData,
    this.color,
    required this.type,
  });
}
