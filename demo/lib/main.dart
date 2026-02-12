import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
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
        fontFamily: 'cursive',
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeroSection(),
                  _buildStatsSection(),
                  _buildFeaturesSection(),
                  _buildExamCategoriesSection(),
                  _buildStudyResourcesSection(),
                  _buildTestimonialsSection(),
                  _buildMotivationalSection(),
                  _buildComingSoonSection(),
                  _buildFooter(),
                ]),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _scrollOffset > 500
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }

  // CUSTOM APP BAR WITH GLASS MORPHISM
  Widget _buildAppBar() {
    final opacity = (_scrollOffset / 100).clamp(0.0, 1.0);

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.85 + (opacity * 0.15)),
      expandedHeight: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 28),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          GestureDetector(
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
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search exams, resources, topics...",
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  suffixIcon: Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: Colors.grey[600],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.black87,
            size: 26,
          ),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8),
                ],
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF2196F3), size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // HERO SECTION WITH PARALLAX
  Widget _buildHeroSection() {
    final parallax = _scrollOffset * 0.5;

    return Container(
      height: 700,
      child: Stack(
        children: [
          // Background with Parallax
          Transform.translate(
            offset: Offset(0, parallax),
            child: Container(
              height: 750,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?q=80&w=2071',
                  ),
                  fit: BoxFit.cover,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.blue.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // COMING SOON BANNER - Positioned at top (matching uploaded image design,

          // Floating Elements Animation
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Positioned(
                top: 100 + (_floatingController.value * 20),
                right: 50,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 150,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1200),
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
                            horizontal: 20,
                            vertical: 8,
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
                            "🎯 YOUR SUCCESS JOURNEY STARTS HERE",
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "Ace Government",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
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
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            shadows: [
                              Shadow(blurRadius: 20, color: Colors.black87),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Comprehensive preparation platform for UPSC, SSC, Banking,\nRailways & more. Your one-stop solution for success.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 50),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCTAButton(
                              "Start Learning",
                              Icons.rocket_launch_rounded,
                              true,
                            ),
                            const SizedBox(width: 20),
                            _buildCTAButton(
                              "Explore Resources",
                              Icons.explore_rounded,
                              false,
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

          // Scroll Indicator
          Positioned(
            bottom: 30,
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
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 30 + (_pulseController.value * 5),
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

  // CTA BUTTON
  Widget _buildCTAButton(String text, IconData icon, bool isPrimary) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
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
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? const Color(0xFF2196F3)
              : Colors.white.withOpacity(0.15),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Colors.white54, width: 2),
          ),
          elevation: isPrimary ? 8 : 0,
        ),
      ),
    );
  }

  // STATS SECTION
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.grey[50]!]),
      ),
      child: Column(
        children: [
          const Text(
            "Experience the flawless preparation platform for competitive exams",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 50),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard(
                "1000+",
                "Study Resources",
                Icons.library_books_rounded,
                Colors.purple,
              ),
              _buildStatCard(
                "500+",
                "Mock Tests",
                Icons.quiz_rounded,
                Colors.orange,
              ),
            ],
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
        width: 220,
        padding: const EdgeInsets.all(30),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FEATURES SECTION
  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Powerful Features for Your Success",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Everything you need to excel in competitive exams",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureCard(
                "AI-Powered Flashcards",
                "Smart learning with adaptive flashcards",
                Icons.auto_awesome_rounded,
                Colors.purple,
                "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=2070",
              ),
              _buildFeatureCard(
                "Previous Year Papers",
                "Comprehensive PYQ database with solutions",
                Icons.history_edu_rounded,
                Colors.blue,
                "https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=2073",
              ),
              _buildFeatureCard(
                "Study Vault",
                "Organized study materials at your fingertips",
                Icons.folder_special_rounded,
                Colors.orange,
                "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?q=80&w=2128",
              ),
              _buildFeatureCard(
                "Mock Tests",
                "Real exam environment simulation",
                Icons.quiz_rounded,
                Colors.green,
                "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?q=80&w=2070",
              ),
              _buildFeatureCard(
                "Progress Tracking",
                "Monitor your growth with analytics",
                Icons.trending_up_rounded,
                Colors.teal,
                "https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=2070",
              ),
              _buildFeatureCard(
                "Study Links Hub",
                "Curated resources from across the web",
                Icons.link_rounded,
                Colors.indigo,
                "https://images.unsplash.com/photo-1488998427799-e3362cec87c3?q=80&w=2070",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String desc,
    IconData icon,
    Color color,
    String imageUrl,
  ) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 340,
            height: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        color.withOpacity(0.3),
                        BlendMode.multiply,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(icon, color: color, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            "Explore",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: color,
                            size: 16,
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
    );
  }

  // EXAM CATEGORIES SECTION
  Widget _buildExamCategoriesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            "Choose Your Exam Category",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Specialized preparation for every competitive exam",
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildExamCategory(
                "UPSC",
                "Civil Services",
                Icons.account_balance_rounded,
                const Color(0xFF1976D2),
                "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?q=80&w=2070",
              ),
              _buildExamCategory(
                "SSC",
                "Staff Selection",
                Icons.work_rounded,
                const Color(0xFF7B1FA2),
                "https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=2070",
              ),
              _buildExamCategory(
                "Banking",
                "IBPS & SBI",
                Icons.account_balance_wallet_rounded,
                const Color(0xFFE65100),
                "https://images.unsplash.com/photo-1541354329998-f4d9a9f9297f?q=80&w=2070",
              ),
              _buildExamCategory(
                "Railways",
                "RRB Exams",
                Icons.train_rounded,
                const Color(0xFF00695C),
                "https://images.unsplash.com/photo-1474487548417-781cb71495f3?q=80&w=2084",
              ),
              _buildExamCategory(
                "Defence",
                "CDS & NDA",
                Icons.shield_rounded,
                const Color(0xFFD32F2F),
                "https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?q=80&w=2080",
              ),
              _buildExamCategory(
                "State PSC",
                "Regional Exams",
                Icons.location_city_rounded,
                const Color(0xFF0288D1),
                "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=2070",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamCategory(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String imageUrl,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 260,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withOpacity(0.8), color.withOpacity(0.95)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
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
    );
  }

  // STUDY RESOURCES SECTION
  Widget _buildStudyResourcesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[100]!, Colors.white]),
      ),
      child: Column(
        children: [
          const Text(
            "Latest Study Resources",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Freshly updated materials to keep you ahead",
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildResourceCard(
                "Current Affairs 2025",
                "Updated daily with latest events",
                "https://images.unsplash.com/photo-1504711434969-e33886168f5c?q=80&w=2070",
                "234 Articles",
              ),
              _buildResourceCard(
                "Quantitative Aptitude",
                "Complete guide with shortcuts",
                "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?q=80&w=2070",
                "180 Topics",
              ),
              _buildResourceCard(
                "General Knowledge",
                "Comprehensive GK database",
                "https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?q=80&w=2070",
                "500+ Facts",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(
    String title,
    String desc,
    String imageUrl,
    String stat,
  ) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.article_rounded,
                          size: 16,
                          color: Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stat,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Start Learning",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TESTIMONIALS SECTION
  Widget _buildTestimonialsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
        ),
      ),
      child: Column(children: []),
    );
  }

  Widget _buildTestimonialCard(
    String name,
    String achievement,
    String testimonial,
    String imageUrl,
  ) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 32, backgroundImage: NetworkImage(imageUrl)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '"$testimonial"',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              5,
              (index) =>
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // MOTIVATIONAL SECTION
  Widget _buildMotivationalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?q=80&w=2073',
          ),
          fit: BoxFit.cover,
        ),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.5),
          ],
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
        child: Column(
          children: [
            // Dr. APJ Abdul Kalam's Image/Icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orangeAccent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 50,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Icon(
              Icons.format_quote_rounded,
              size: 50,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              '"DREAM IS NOT THAT WHICH YOU SEE\nWHILE SLEEPING,\nIT IS SOMETHING THAT DOES NOT\nLET YOU SLEEP"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.5,
                letterSpacing: 0.8,
                shadows: [Shadow(blurRadius: 15, color: Colors.black)],
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "- Dr. APJ Abdul Kalam",
              style: TextStyle(
                color: Colors.orangeAccent.withOpacity(0.95),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Missile Man of India • People's President",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    "Dr. Kalam's Words of Wisdom",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "🌟 \"All of us do not have equal talent. But, all of us\nhave an equal opportunity to develop our talents.\"\n\n"
                    "💡 \"If you want to shine like a sun,\nfirst burn like a sun.\"\n\n"
                    "📚 \"Learning gives creativity,\ncreativity leads to thinking,\nthinking provides knowledge,\nknowledge makes you great.\"\n\n"
                    "🎯 \"You have to dream before your\ndreams can come true.\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 2.4,
                      fontStyle: FontStyle.italic,
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

  // COMING SOON / UNDER MAINTENANCE SECTION
  Widget _buildComingSoonSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E),
            const Color(0xFF0D47A1),
            const Color(0xFF01579B),
          ],
        ),
      ),
      child: Column(
        children: [
          // Animated Icon
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingController.value * 15),
                child: Transform.rotate(
                  angle: _floatingController.value * 0.1,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.deepOrange.withOpacity(0.3),
                        ],
                      ),
                      border: Border.all(color: Colors.white30, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 50),

          // Main Heading
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.02),
                child: child,
              );
            },
            child: const Text(
              "🎉 EXCITING NEWS!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            "Mobile App Launching Soon",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1.2,
              shadows: [Shadow(blurRadius: 20, color: Colors.black54)],
            ),
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: const Text(
              "⚙️ Currently Under Development & Maintenance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Dr. Kalam's Quote for Launch Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orangeAccent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.orangeAccent,
                  size: 30,
                ),
                const SizedBox(height: 12),
                const Text(
                  '"Excellence is a continuous process\nand not an accident."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "- Dr. APJ Abdul Kalam",
                  style: TextStyle(
                    color: Colors.orangeAccent.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          const Text(
            "We're working hard to bring you the best exam preparation experience\non mobile. Stay tuned for the official launch!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.6),
          ),
          const SizedBox(height: 60),

          // Feature Preview Cards
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildComingSoonFeature(
                Icons.phone_android_rounded,
                "Native App",
                "iOS & Android",
                Colors.blue,
              ),
              _buildComingSoonFeature(
                Icons.offline_bolt_rounded,
                "Offline Mode",
                "Study Anywhere",
                Colors.green,
              ),
              _buildComingSoonFeature(
                Icons.notifications_active_rounded,
                "Smart Alerts",
                "Stay Updated",
                Colors.orange,
              ),
              _buildComingSoonFeature(
                Icons.sync_rounded,
                "Cloud Sync",
                "Cross Device",
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 60),

          // Notify Me Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                // Show notification signup dialog
              },
              icon: const Icon(Icons.notifications_active_rounded, size: 24),
              label: const Text(
                "Notify Me When Launched",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildComingSoonFeature(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // FOOTER
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "RIZ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            "Empowering aspirants to achieve their dreams",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 40,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildFooterLink("About Us"),
              _buildFooterLink("Courses"),
              _buildFooterLink("Resources"),
              _buildFooterLink("Blog"),
              _buildFooterLink("Contact"),
              _buildFooterLink("Privacy Policy"),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.facebook_rounded),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.telegram_rounded),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.youtube_searched_for_rounded),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.email_rounded),
            ],
          ),
          const SizedBox(height: 40),
          Container(height: 1, width: 300, color: Colors.white24),
          const SizedBox(height: 30),
          Text(
            "© 2025 RIZ Learning Hub. All rights reserved.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Made with ❤️ for every aspiring achiever",
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }

  // DRAWER
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'RIZ',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Learning Hub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard_rounded, 'Dashboard', true),
            _buildDrawerItem(
              Icons.add_box_rounded,
              'Add Study Materials',
              false,
            ),
            _buildDrawerItem(Icons.style_rounded, 'AI Flashcards', false),
            _buildDrawerItem(Icons.link_rounded, 'Study Links', false),
            _buildDrawerItem(
              Icons.history_edu_rounded,
              "PYQ's (Past Papers)",
              false,
            ),
            const Divider(color: Colors.white30, height: 32),
            _buildDrawerItem(Icons.settings_rounded, 'Settings', false),
            _buildDrawerItem(
              Icons.help_outline_rounded,
              'Help & Support',
              false,
            ),
          ],
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
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: isActive
            ? const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              )
            : null,
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
