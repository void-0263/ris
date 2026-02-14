import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';

void main() {
  // Lock orientation to portrait for mobile
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      home: const RISHomePage(),
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

    // Start initial animations
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
              _buildExamCategoriesSection(),
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

  // MOBILE-OPTIMIZED APP BAR
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
        // Search Button (opens search screen)
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            color: Colors.black87,
            size: 24,
          ),
          onPressed: () {
            // Navigate to search screen
            showSearch(context: context, delegate: ExamSearchDelegate());
          },
          splashRadius: 24,
        ),
        // Notification with Pulse animation
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
                onPressed: () {
                  // Show notifications
                  _showNotifications();
                },
                splashRadius: 24,
              ),
            );
          },
        ),
        // Profile with animation
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
                // Navigate to profile
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

  // MOBILE-OPTIMIZED HERO SECTION
  Widget _buildHeroSection() {
    final parallax = _scrollOffset * 0.3; // Reduced for mobile

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Responsive height
      child: Stack(
        children: [
          // Background with Parallax
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

          // Content
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

          // Scroll Indicator
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

  // MOBILE CTA BUTTON
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
          onPressed: () {},
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

  // STATS SECTION
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

  // FEATURES SECTION (Mobile GridView)
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
        'title': 'Study Vault',
        'desc': 'Organized materials',
        'icon': Icons.folder_special_rounded,
        'color': Colors.orange,
      },
    ];

    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        (screenWidth - 56) /
        2; // 56 = 20 (left padding) + 20 (right padding) + 16 (spacing)

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
          const Text(
            "Powerful Features",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Ubuntu',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Everything you need to excel",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white70,
              fontFamily: 'Ubuntu',
            ),
          ),
          const SizedBox(height: 40),

          // Using Wrap with center alignment to center the third card
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center, // This centers the items
            children: features.map((feature) {
              return SizedBox(
                width: cardWidth,
                child: _buildMobileFeatureCard(
                  feature['title'] as String,
                  feature['desc'] as String,
                  feature['icon'] as IconData,
                  feature['color'] as Color,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFeatureCard(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to feature details
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
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
              desc,
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
    );
  }

  // EXAM CATEGORIES (Mobile ScrollView)
  Widget _buildExamCategoriesSection() {
    final categories = [
      {
        'title': 'TNPSC',
        'subtitle': 'State Services',
        'color': const Color(0xFFBDB76B),
        'icon': Icons.public_rounded,
      },
      {
        'title': 'UPSC',
        'subtitle': 'Civil Services',
        'color': const Color(0xFF1976D2),
        'icon': Icons.account_balance_rounded,
      },
      {
        'title': 'SSC',
        'subtitle': 'Staff Selection',
        'color': const Color(0xFF7B1FA2),
        'icon': Icons.work_rounded,
      },
      {
        'title': 'Banking',
        'subtitle': 'IBPS & SBI',
        'color': const Color(0xFFE65100),
        'icon': Icons.account_balance_wallet_rounded,
      },
      {
        'title': 'Railways',
        'subtitle': 'RRB Exams',
        'color': const Color(0xFF00695C),
        'icon': Icons.train_rounded,
      },
      {
        'title': 'Defence',
        'subtitle': 'CDS & NDA',
        'color': const Color(0xFFD32F2F),
        'icon': Icons.shield_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Choose Your Category",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1976D2),
                fontFamily: 'Ubuntu',
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildMobileExamCategory(
                    cat['title'] as String,
                    cat['subtitle'] as String,
                    cat['icon'] as IconData,
                    cat['color'] as Color,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileExamCategory(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to category
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Ubuntu',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontFamily: 'Ubuntu',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // STUDY RESOURCES
  Widget _buildStudyResourcesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[50]!, Colors.white]),
      ),
      child: Column(
        children: [
          const Text(
            "Latest Study Resources",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Ubuntu',
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 32),
          _buildMobileResourceCard(
            "Current Affairs->",
            "Updated daily with latest events",
            "✅",
            Icons.article_rounded,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildMobileResourceCard(
            "Quantitative Aptitude->",
            "Complete guide with shortcuts",
            "✅",
            Icons.calculate_rounded,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildMobileResourceCard(
            "General Knowledge->",
            "Comprehensive GK database",
            "✅",
            Icons.public_rounded,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileResourceCard(
    String title,
    String desc,
    String stat,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {},
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: 'Ubuntu',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
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

  // MOTIVATIONAL SECTION
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

  // FOOTER
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

  // DRAWER (Mobile Navigation)
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

  // Helper Methods
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Ubuntu',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No new notifications',
              style: TextStyle(fontFamily: 'Ubuntu'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile() {
    // Navigate to profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profile feature coming soon!',
          style: TextStyle(fontFamily: 'Ubuntu'),
        ),
      ),
    );
  }
}

// Search Delegate for Mobile
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
