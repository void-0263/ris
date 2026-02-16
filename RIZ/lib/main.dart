import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'loading_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'profile_screen.dart';
import 'profile_service.dart';
import 'current_affairs_screen.dart';
import 'quantitative_aptitude_screen.dart';
import 'general_knowledge_screen.dart';
import 'categories_section.dart';
import 'feature_screens.dart'; // 👈 ADDED

// ✅ CRITICAL: Background handler MUST be at top level (outside any class)
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📱 Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    print('⚠️ Firebase init: $e');
  }

  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  runApp(const RISApp());
}

class RISApp extends StatelessWidget {
  const RISApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Ubuntu',
      ),
      home: const AppWithLoading(),
    );
  }
}

class RISHomePage extends StatefulWidget {
  const RISHomePage({super.key});

  @override
  State<RISHomePage> createState() => _RISHomePageState();
}

class _RISHomePageState extends State<RISHomePage>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _logoController;
  late AnimationController _searchController;
  late AnimationController _profileController;
  late AnimationController _notificationController;

  @override
  void initState() {
    super.initState();

    ProfileService().updateStreak();

    _scrollController.addListener(() {
      if (_scrollOffset != _scrollController.offset) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _searchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _profileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _notificationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 100), () {
      _logoController.forward();
      _searchController.forward();
      _profileController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _logoController.dispose();
    _searchController.dispose();
    _profileController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  void _scrollToCategories() {
    final screenHeight = MediaQuery.of(context).size.height;
    final targetPosition = (screenHeight * 0.75) + 900;

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOutCubic,
    );
  }

  void _scrollToResources() {
    final screenHeight = MediaQuery.of(context).size.height;
    final targetPosition = (screenHeight * 0.75) + 1200;

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildHeroSection(),
              _buildStatsSection(),
              _buildFeaturesSection(),
              const CategoriesSection(),
              _buildStudyResourcesSection(),
              _buildMotivationalSection(),
              _buildFooter(),
            ]),
          ),
        ],
      ),
      floatingActionButton: _scrollOffset > 500
          ? ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _profileController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutCubic,
                  );
                },
                backgroundColor: const Color(0xFF2196F3),
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar() {
    final opacity = (_scrollOffset / 100).clamp(0.0, 1.0);

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.85 + (opacity * 0.15)),
      expandedHeight: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 26),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        splashRadius: 24,
      ),
      title: SlideTransition(
        position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
            ),
        child: FadeTransition(
          opacity: _logoController,
          child: GestureDetector(
            onTap: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                "RIZ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Ubuntu',
                  fontStyle: FontStyle.italic,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            color: Colors.black87,
            size: 24,
          ),
          onPressed: () {
            showSearch(context: context, delegate: ExamSearchDelegate());
          },
          splashRadius: 24,
        ),
        AnimatedBuilder(
          animation: _notificationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_notificationController.value * 0.1),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                  size: 24,
                  shadows: [
                    Shadow(
                      color: Colors.blue.withOpacity(
                        _notificationController.value * 0.3,
                      ),
                      blurRadius: 10,
                    ),
                  ],
                ),
                onPressed: () async {
                  final notificationService = NotificationService();
                  bool isEnabled = await notificationService
                      .areNotificationsEnabled();

                  if (!isEnabled) {
                    bool granted = await notificationService
                        .requestPermission();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            granted
                                ? '✅ Notifications enabled!'
                                : '❌ Notifications denied',
                            style: const TextStyle(fontFamily: 'Ubuntu'),
                          ),
                          backgroundColor: granted ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  } else {
                    _showNotificationSettings();
                  }
                },
                splashRadius: 24,
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _profileController,
                curve: Curves.elasticOut,
              ),
            ),
            child: GestureDetector(
              onTap: () {
                _navigateToProfile();
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF2196F3), size: 20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final parallax = _scrollOffset * 0.3;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Stack(
        children: [
          Transform.translate(
            offset: Offset(0, parallax),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=2070',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.blue.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOut,
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.orangeAccent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              "🎯 YOUR SUCCESS STARTS HERE",
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Ubuntu',
                                fontStyle: FontStyle.italic,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Ace Government",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Ubuntu',
                              height: 1.1,
                              shadows: [
                                Shadow(blurRadius: 20, color: Colors.black87),
                              ],
                            ),
                          ),
                          const Text(
                            "Sector Exams",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64B5F6),
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Ubuntu',
                              height: 1.1,
                              shadows: [
                                Shadow(blurRadius: 20, color: Colors.black87),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Comprehensive preparation for TNPSC, UPSC, SSC, Banking & more",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Ubuntu',
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Column(
                            children: [
                              _buildMobileCTAButton(
                                "Start Learning",
                                Icons.rocket_launch_rounded,
                                true,
                              ),
                              const SizedBox(height: 12),
                              _buildMobileCTAButton(
                                "Explore Resources",
                                Icons.explore_rounded,
                                true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.7 - (_pulseController.value * 0.3),
                  child: Column(
                    children: [
                      const Text(
                        "Scroll to explore",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Ubuntu',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 24 + (_pulseController.value * 4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCTAButton(String text, IconData icon, bool isPrimary) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            if (text == "Start Learning") {
              _scrollToCategories();
            } else if (text == "Explore Resources") {
              _scrollToResources();
            }
          },
          icon: Icon(icon, size: 20),
          label: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Ubuntu',
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? const Color(0xFF2196F3)
                : Colors.white.withOpacity(0.15),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: isPrimary
                  ? BorderSide.none
                  : const BorderSide(color: Colors.white54, width: 2),
            ),
            elevation: isPrimary ? 8 : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.grey[50]!]),
      ),
      child: Column(
        children: [
          const Text(
            "Trusted Preparation Platform",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1976D2),
              fontFamily: 'Ubuntu',
            ),
          ),
          const SizedBox(height: 40),
          _buildStatCard(
            "1000+",
            "Study Resources",
            Icons.library_books_rounded,
            Colors.purple,
          ),
          const SizedBox(height: 20),
          _buildStatCard(
            "500+",
            "Practice Questions",
            Icons.quiz_rounded,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, double animValue, child) {
        return Transform.scale(
          scale: 0.8 + (animValue * 0.2),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontFamily: 'Ubuntu',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontFamily: 'Ubuntu',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'title': 'Digital Flashcards',
        'desc': 'Smart adaptive learning',
        'icon': Icons.auto_awesome_rounded,
        'color': Colors.purple,
      },
      {
        'title': 'PYQ\'s',
        'desc': 'PYQ database',
        'icon': Icons.history_edu_rounded,
        'color': Colors.blue,
      },
      {
        'title': 'Study Links',
        'desc': 'Organized materials',
        'icon': Icons.folder_special_rounded,
        'color': Colors.orange,
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 56) / 2;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.center,
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
        ),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: const Text(
              "Powerful Features",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Ubuntu',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Opacity(opacity: value, child: child);
            },
            child: const Text(
              "Everything you need to succeed in one place",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
                fontFamily: 'Ubuntu',
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _AnimatedFeatureCard(
                delay: 0,
                width: cardWidth,
                title: features[0]['title'] as String,
                desc: features[0]['desc'] as String,
                icon: features[0]['icon'] as IconData,
                color: features[0]['color'] as Color,
              ),
              _AnimatedFeatureCard(
                delay: 200,
                width: cardWidth,
                title: features[1]['title'] as String,
                desc: features[1]['desc'] as String,
                icon: features[1]['icon'] as IconData,
                color: features[1]['color'] as Color,
              ),
              _AnimatedFeatureCard(
                delay: 400,
                width: cardWidth,
                title: features[2]['title'] as String,
                desc: features[2]['desc'] as String,
                icon: features[2]['icon'] as IconData,
                color: features[2]['color'] as Color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyResourcesSection() {
    return const StudyResourcesSection();
  }

  Widget _buildMotivationalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1976D2), const Color(0xFF0D47A1)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orangeAccent, width: 2),
            ),
            child: const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 40,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.format_quote_rounded,
            size: 40,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            '"Dream is not what you see while sleeping,\nit is something that does not let you sleep"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Ubuntu',
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "- Dr. APJ Abdul Kalam",
            style: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.95),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Ubuntu',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "RIZ",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 24,
                letterSpacing: 2,
                fontFamily: 'Ubuntu',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Empowering aspirants to achieve their dreams",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Ubuntu',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.facebook_rounded),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.telegram_rounded),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.email_rounded),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, width: 200, color: Colors.white24),
          const SizedBox(height: 20),
          Text(
            "© 2026 RIZ Learning Hub",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontFamily: 'Ubuntu',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Made with ❤️ for every aspiring achiever",
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Ubuntu',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'RIZ',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          fontFamily: 'Ubuntu',
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Learning Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(Icons.home_rounded, 'Home', true),
                    _buildDrawerItem(
                      Icons.style_rounded,
                      'Digital Flashcards',
                      true,
                    ),
                    _buildDrawerItem(Icons.history_edu_rounded, "PYQ's", true),
                    _buildDrawerItem(Icons.link_rounded, 'Study Links', true),
                    const Divider(
                      color: Colors.white30,
                      height: 32,
                      indent: 20,
                      endIndent: 20,
                    ),
                    _buildDrawerItem(Icons.settings_rounded, 'Settings', true),
                    _buildDrawerItem(
                      Icons.help_outline_rounded,
                      'Help & Support',
                      true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 15,
            fontFamily: 'Ubuntu',
          ),
        ),
        trailing: isActive
            ? const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              )
            : null,
        onTap: () => Navigator.pop(context),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🔔 Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Ubuntu',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '✅ Notifications are enabled!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontFamily: 'Ubuntu',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await NotificationService().disableNotifications();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notifications disabled',
                        style: TextStyle(fontFamily: 'Ubuntu'),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Disable Notifications',
                style: TextStyle(fontFamily: 'Ubuntu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }
}

class ExamSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2196F3),
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Ubuntu'),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'Ubuntu',
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text(
        'Search results for: $query',
        style: const TextStyle(fontFamily: 'Ubuntu'),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = ['UPSC', 'SSC', 'Banking', 'TNPSC', 'Railways'];
    final filtered = suggestions
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            filtered[index],
            style: const TextStyle(fontFamily: 'Ubuntu'),
          ),
          onTap: () => query = filtered[index],
        );
      },
    );
  }
}

// Study Resources Section
class StudyResourcesSection extends StatefulWidget {
  const StudyResourcesSection({super.key});

  @override
  State<StudyResourcesSection> createState() => _StudyResourcesSectionState();
}

class _StudyResourcesSectionState extends State<StudyResourcesSection>
    with TickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction > 0.3 && !_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('study-resources-section'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.grey[50]!, Colors.white]),
        ),
        child: Column(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: const Text(
                  "Latest Study Resources",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Ubuntu',
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildAnimatedResourceCard(
              "Current Affairs→",
              "Updated daily with latest events",
              "✅",
              Icons.article_rounded,
              Colors.blue,
              delay: 0,
            ),
            const SizedBox(height: 16),
            _buildAnimatedResourceCard(
              "Quantitative Aptitude→",
              "Complete guide with shortcuts",
              "✅",
              Icons.calculate_rounded,
              Colors.purple,
              delay: 150,
            ),
            const SizedBox(height: 16),
            _buildAnimatedResourceCard(
              "General Knowledge→",
              "Comprehensive GK database",
              "✅",
              Icons.public_rounded,
              Colors.orange,
              delay: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedResourceCard(
    String title,
    String desc,
    String stat,
    IconData icon,
    Color color, {
    required int delay,
  }) {
    return AnimatedResourceCard(
      title: title,
      desc: desc,
      stat: stat,
      icon: icon,
      color: color,
      controller: _controller,
      delay: delay,
    );
  }
}

class AnimatedResourceCard extends StatefulWidget {
  final String title;
  final String desc;
  final String stat;
  final IconData icon;
  final Color color;
  final AnimationController controller;
  final int delay;

  const AnimatedResourceCard({
    super.key,
    required this.title,
    required this.desc,
    required this.stat,
    required this.icon,
    required this.color,
    required this.controller,
    required this.delay,
  });

  @override
  State<AnimatedResourceCard> createState() => _AnimatedResourceCardState();
}

class _AnimatedResourceCardState extends State<AnimatedResourceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );

    widget.controller.addListener(_onParentControllerChange);
  }

  void _onParentControllerChange() {
    if (widget.controller.value > 0.1 &&
        _cardController.status == AnimationStatus.dismissed) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) {
          _cardController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onParentControllerChange);
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildMobileResourceCard(),
        ),
      ),
    );
  }

  Widget _buildMobileResourceCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ProfileService().trackResourceAccessed();

        Widget screen;
        if (widget.title.contains('Current Affairs')) {
          screen = const CurrentAffairsScreen();
        } else if (widget.title.contains('Quantitative Aptitude')) {
          screen = const QuantitativeAptitudeScreen();
        } else if (widget.title.contains('General Knowledge')) {
          screen = const GeneralKnowledgeScreen();
        } else {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: 'Ubuntu',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.desc,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontFamily: 'Ubuntu',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.stat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.color,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedFeatureCard extends StatefulWidget {
  final int delay;
  final double width;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const _AnimatedFeatureCard({
    required this.delay,
    required this.width,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });

  @override
  State<_AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<_AnimatedFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: SizedBox(
                width: widget.width,
                child: _FeatureCardContent(
                  title: widget.title,
                  desc: widget.desc,
                  icon: widget.icon,
                  color: widget.color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCardContent extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const _FeatureCardContent({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });

  @override
  State<_FeatureCardContent> createState() => _FeatureCardContentState();
}

class _FeatureCardContentState extends State<_FeatureCardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // 👇 ADDED: Navigation method
  void _navigateToFeature(BuildContext context) {
    Widget? screen;

    if (widget.title == 'Digital Flashcards') {
      screen = const DigitalFlashcardsScreen();
    } else if (widget.title == 'PYQ\'s') {
      screen = const PYQsScreen();
    } else if (widget.title == 'Study Links') {
      screen = const StudyVaultScreen();
    }

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _navigateToFeature(context); // 👈 ADDED: Call navigation
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.05 : 0.1),
                blurRadius: _isPressed ? 10 : 15,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 32),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  fontFamily: 'Ubuntu',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Ubuntu',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppWithLoading extends StatefulWidget {
  const AppWithLoading({super.key});

  @override
  State<AppWithLoading> createState() => _AppWithLoadingState();
}

class _AppWithLoadingState extends State<AppWithLoading> {
  bool _isLoading = true;

  void _onLoadingComplete() {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(onLoadingComplete: _onLoadingComplete);
    }
    return const RISHomePage();
  }
}
