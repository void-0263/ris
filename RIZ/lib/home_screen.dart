import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_service.dart';
import 'categories_section.dart';
import 'current_affairs_screen.dart';
import 'quantitative_aptitude_screen.dart';
import 'general_knowledge_screen.dart';
import 'feature_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileService _profileService = ProfileService();
  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    _profileService.updateStreak();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }
  }

  Map<String, dynamic> _parseStats(AsyncSnapshot<DocumentSnapshot> snapshot) {
    final fallback = {
      'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Learner',
      'totalStudySeconds': 0,
      'resourcesAccessed': 0,
      'questionsAttempted': 0,
      'currentStreak': 0,
      'longestStreak': 0,
    };
    if (!snapshot.hasData || !snapshot.data!.exists) return fallback;
    final data = snapshot.data!.data() as Map<String, dynamic>;
    return {
      'name': data['name'] ?? fallback['name'],
      'totalStudySeconds': data['totalStudySeconds'] ?? 0,
      'resourcesAccessed': data['resourcesAccessed'] ?? 0,
      'questionsAttempted': data['questionsAttempted'] ?? 0,
      'currentStreak': data['currentStreak'] ?? 0,
      'longestStreak': data['longestStreak'] ?? 0,
    };
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning 🌅';
    if (h >= 12 && h < 17) return 'Good Afternoon ☀️';
    if (h >= 17 && h < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          final stats = _parseStats(snapshot);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(stats),
                    _buildQuickStats(stats),
                    _buildStreakCard(stats),
                    _buildQuickActions(),
                    _buildExamCategories(),
                    _buildUpcomingExams(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: const Color(0xFF2196F3),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text('Dashboard',
            style: TextStyle(
                fontFamily: 'Ubuntu',
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 18)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(Map<String, dynamic> stats) {
    final name = (stats['name'] ?? 'Learner') as String;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontFamily: 'Ubuntu')),
                const SizedBox(height: 4),
                Text(name.split(' ').first,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Ubuntu')),
                const SizedBox(height: 8),
                Text('Keep up the great work! 🚀',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontFamily: 'Ubuntu')),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'A',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Ubuntu')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    final totalSeconds = (stats['totalStudySeconds'] ?? 0) as int;
    final studyTimeStr = _profileService.formatStudyTime(totalSeconds);
    final resources = (stats['resourcesAccessed'] ?? 0).toString();
    final questions = (stats['questionsAttempted'] ?? 0).toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _statCard(studyTimeStr, 'Study Time', Icons.timer_rounded,
              const Color(0xFF4CAF50), 0),
          const SizedBox(width: 12),
          _statCard(resources, 'Resources', Icons.library_books_rounded,
              const Color(0xFFFF9800), 1),
          const SizedBox(width: 12),
          _statCard(questions, 'Questions\nFaced', Icons.quiz_rounded,
              const Color(0xFF9C27B0), 2),
        ],
      ),
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color, int index) {
    return Expanded(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 400 + (index * 100)),
        curve: Curves.easeOutBack,
        builder: (_, double v, child) => Transform.scale(
            scale: v, child: Opacity(opacity: v.clamp(0, 1), child: child)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontFamily: 'Ubuntu')),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'Ubuntu')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(Map<String, dynamic> stats) {
    final current = (stats['currentStreak'] ?? 0) as int;
    final longest = (stats['longestStreak'] ?? 0) as int;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔥 Current Streak',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Ubuntu')),
                const SizedBox(height: 8),
                Text('$current ${current == 1 ? 'Day' : 'Days'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Ubuntu')),
                const SizedBox(height: 4),
                Text('Best: $longest days',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Ubuntu')),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Current Affairs',
        'icon': Icons.article_rounded,
        'color': const Color(0xFF2196F3),
        'screen': 'current_affairs'
      },
      {
        'label': 'Quantitative',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF9C27B0),
        'screen': 'quant'
      },
      {
        'label': 'General Knowledge',
        'icon': Icons.public_rounded,
        'color': const Color(0xFFFF9800),
        'screen': 'gk'
      },
      {
        'label': 'Flashcards',
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFF4CAF50),
        'screen': 'flashcards'
      },
      {
        'label': "PYQ's",
        'icon': Icons.history_edu_rounded,
        'color': const Color(0xFFD32F2F),
        'screen': 'pyqs'
      },
      {
        'label': 'Study Links',
        'icon': Icons.folder_special_rounded,
        'color': const Color(0xFF00695C),
        'screen': 'study_links'
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Ubuntu',
                  color: Color(0xFF1565C0))),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
            ),
            itemCount: actions.length,
            itemBuilder: (context, i) {
              final action = actions[i];
              final color = action['color'] as Color;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _navigate(action['screen'] as String);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: color.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(action['icon'] as IconData,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(action['label'] as String,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                                fontFamily: 'Ubuntu'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigate(String screen) {
    Widget? dest;
    switch (screen) {
      case 'current_affairs':
        dest = const CurrentAffairsScreen();
        break;
      case 'quant':
        dest = const QuantitativeAptitudeScreen();
        break;
      case 'gk':
        dest = const GeneralKnowledgeScreen();
        break;
      case 'flashcards':
        dest = const DigitalFlashcardsScreen();
        break;
      case 'pyqs':
        dest = const PYQsScreen();
        break;
      case 'study_links':
        dest = const StudyVaultScreen();
        break;
    }
    if (dest != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => dest!));
    }
  }

  Widget _buildExamCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exam Categories',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Ubuntu',
                  color: Color(0xFF1565C0))),
          const SizedBox(height: 14),
          const CategoriesSection(),
        ],
      ),
    );
  }

  Widget _buildUpcomingExams() {
    final exams = [
      {
        'name': 'TNPSC Group 1 Prelims',
        'date': 'Sep 6, 2026',
        'days': 193,
        'color': const Color(0xFFBDB76B)
      },
      {
        'name': 'UPSC Civil Services Prelims',
        'date': 'May 24, 2026',
        'days': 88,
        'color': const Color(0xFF1976D2)
      },
      {
        'name': 'SSC CGL Tier 1',
        'date': 'May–Jun 2026',
        'days': 75,
        'color': const Color(0xFF7B1FA2)
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming Exams',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Ubuntu',
                  color: Color(0xFF1565C0))),
          const SizedBox(height: 14),
          ...exams.map((e) {
            final color = e['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                      width: 4,
                      height: 50,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['name'] as String,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Ubuntu',
                                color: Colors.black87)),
                        const SizedBox(height: 3),
                        Text(e['date'] as String,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontFamily: 'Ubuntu')),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('${e['days']}d',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontFamily: 'Ubuntu')),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
