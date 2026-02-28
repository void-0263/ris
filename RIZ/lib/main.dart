import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'loading_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'profile_screen.dart';
import 'profile_service.dart';
import 'current_affairs_screen.dart';
import 'quantitative_aptitude_screen.dart';
import 'general_knowledge_screen.dart';
import 'categories_section.dart';
import 'feature_screens.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'search_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// ── Global theme notifier ─────────────────────────────────
// Default: Light (not System) as requested
final ValueNotifier<ThemeMode> appThemeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

// ── Background FCM handler (top-level) ───────────────────
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('📱 Background message: ${message.messageId}');
}

// ─────────────────────────────────────────────
// main()
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('❌ Firebase init error: $e');
    }
  }

  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  try {
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) debugPrint('✅ FCM TOKEN: $token');
  } catch (e) {
    debugPrint('⚠️ FCM setup error: $e');
  }

  // ── Load saved theme preference ───────────────────────
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme') ?? 'Light'; // default Light
  appThemeNotifier.value = _themeFromString(savedTheme);

  runApp(const RISApp());
}

ThemeMode _themeFromString(String theme) {
  switch (theme) {
    case 'Dark':
      return ThemeMode.dark;
    case 'Light':
      return ThemeMode.light;
    default:
      return ThemeMode.light; // default Light
  }
}

// ─────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────
class RISApp extends StatelessWidget {
  const RISApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (_, themeMode, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,

        // ── LIGHT THEME ───────────────────────────────────
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          fontFamily: 'Ubuntu',
          // Cards, drawers, dialogs — all white in light mode
          cardColor: Colors.white,
          drawerTheme:
              const DrawerThemeData(backgroundColor: Color(0xFF1565C0)),
        ),

        // ── DARK THEME — fully readable ───────────────────
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: 'Ubuntu',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
            surface: const Color(0xFF1A1A2E),
            onSurface: Colors.white,
            primary: const Color(0xFF2196F3),
            onPrimary: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          cardColor: const Color(0xFF1E1E30),
          // AppBar: dark navy, white text
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Ubuntu'),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          // ListTile text — white
          listTileTheme: const ListTileThemeData(
            textColor: Colors.white,
            iconColor: Colors.white70,
          ),
          // Text fields — dark background, white text
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF252538),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF3A3A55))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF3A3A55))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF2196F3), width: 2)),
          ),
          // Cards
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E30),
            shadowColor: Colors.black.withValues(alpha: 0.4),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          // Switches, checkboxes
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith((s) =>
                s.contains(MaterialState.selected)
                    ? const Color(0xFF2196F3)
                    : Colors.grey),
            trackColor: MaterialStateProperty.resolveWith((s) =>
                s.contains(MaterialState.selected)
                    ? const Color(0xFF2196F3).withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.3)),
          ),
          // Drawer
          drawerTheme:
              const DrawerThemeData(backgroundColor: Color(0xFF1A1A2E)),
          // Divider
          dividerTheme:
              const DividerThemeData(color: Color(0xFF2A2A40), thickness: 1),
          // Bottom sheet
          bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF1E1E30), showDragHandle: false),
          // Dialog
          dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E1E30),
              titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Ubuntu'),
              contentTextStyle: TextStyle(
                  color: Colors.white70, fontSize: 14, fontFamily: 'Ubuntu')),
          // Dropdown
          dropdownMenuTheme: const DropdownMenuThemeData(
              textStyle: TextStyle(color: Colors.white, fontFamily: 'Ubuntu')),
          // Popup menu (for dropdowns in settings)
          popupMenuTheme: const PopupMenuThemeData(
              color: Color(0xFF1E1E30),
              textStyle: TextStyle(color: Colors.white, fontFamily: 'Ubuntu')),
          // TextTheme — make ALL text white in dark mode
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            displayMedium: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            displaySmall: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            headlineLarge: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            headlineMedium:
                TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            headlineSmall: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            titleLarge: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            titleMedium: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            titleSmall: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'Ubuntu'),
            bodySmall: TextStyle(color: Colors.white60, fontFamily: 'Ubuntu'),
            labelLarge: TextStyle(color: Colors.white, fontFamily: 'Ubuntu'),
            labelMedium: TextStyle(color: Colors.white70, fontFamily: 'Ubuntu'),
            labelSmall: TextStyle(color: Colors.white60, fontFamily: 'Ubuntu'),
          ),
        ),

        // ── Named routes ──────────────────────────────────
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashRouter(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const AppWithLoading(),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SPLASH ROUTER
// Decides: show notification gate (first install) OR
//          auto-login (returning user) OR login screen
// Also handles the "restart after long break" logic
// ─────────────────────────────────────────────
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenNotif = prefs.getBool('seen_notif_gate') ?? false;

    if (!hasSeenNotif) {
      // First install — mark seen and show notification gate
      await prefs.setBool('seen_notif_gate', true);
      _navigateTo(const NotificationPermissionGate());
      return;
    }

    // ✅ Wait for Firebase Auth to restore session from cache.
    // authStateChanges() fires immediately with cached session — no network needed.
    // We take the FIRST value only (not an ongoing listener).
    final user = await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (!mounted) return;

    if (user != null) {
      _navigateTo(const AppWithLoading());
    } else {
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2196F3)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NOTIFICATION PERMISSION GATE  (first install only)
// ─────────────────────────────────────────────
class NotificationPermissionGate extends StatefulWidget {
  const NotificationPermissionGate({super.key});

  @override
  State<NotificationPermissionGate> createState() =>
      _NotificationPermissionGateState();
}

class _NotificationPermissionGateState extends State<NotificationPermissionGate>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ✅ seen_notif_gate is already set by SplashRouter before we get here
  // Just navigate to LoginScreen
  void _proceed() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _allow() async {
    setState(() => _loading = true);
    await NotificationService().requestPermission();
    _proceed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.translate(
                  offset: Offset(0, _slideAnim.value), child: child),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 36),
                  const Text('Stay Updated!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Ubuntu')),
                  const SizedBox(height: 14),
                  Text(
                    'Get notified about exam dates, daily current affairs, and study reminders.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontFamily: 'Ubuntu',
                        height: 1.6),
                  ),
                  const SizedBox(height: 36),
                  _benefitRow(Icons.event_rounded, 'Exam date reminders'),
                  const SizedBox(height: 12),
                  _benefitRow(Icons.article_rounded, 'Daily current affairs'),
                  const SizedBox(height: 12),
                  _benefitRow(Icons.alarm_rounded, 'Study reminders'),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _allow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Color(0xFF2196F3)))
                          : const Text('Allow Notifications',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Ubuntu')),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _loading ? null : _proceed,
                    child: Text('Skip for now',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontFamily: 'Ubuntu')),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 14),
      Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Ubuntu',
              fontWeight: FontWeight.w500)),
    ]);
  }
}

// ─────────────────────────────────────────────
// AppWithLoading — loading screen → home
// ─────────────────────────────────────────────
class AppWithLoading extends StatefulWidget {
  const AppWithLoading({super.key});

  @override
  State<AppWithLoading> createState() => _AppWithLoadingState();
}

class _AppWithLoadingState extends State<AppWithLoading> {
  bool _isLoading = true;

  void _onLoadingComplete() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(onLoadingComplete: _onLoadingComplete);
    }
    return const RISHomePage();
  }
}

// ─────────────────────────────────────────────
// APP LIFECYCLE WATCHER  — restarts after long break
// Wrap RISHomePage with this
// ─────────────────────────────────────────────
class AppLifecycleWatcher extends StatefulWidget {
  final Widget child;
  const AppLifecycleWatcher({super.key, required this.child});

  @override
  State<AppLifecycleWatcher> createState() => _AppLifecycleWatcherState();
}

class _AppLifecycleWatcherState extends State<AppLifecycleWatcher>
    with WidgetsBindingObserver {
  // Restart if app was backgrounded for longer than this
  static const _restartThreshold = Duration(hours: 2);
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pausedAt = DateTime.now();
      debugPrint('⏸️ App paused at $_pausedAt');
    }

    if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final away = DateTime.now().difference(_pausedAt!);
      debugPrint('▶️ App resumed after ${away.inMinutes} min');

      if (away >= _restartThreshold && mounted) {
        debugPrint('🔄 Long break detected — restarting to /splash');
        _pausedAt = null;
        // Navigate to splash which re-checks auth state
        Navigator.of(context).pushNamedAndRemoveUntil('/splash', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────────────────────────
// HOME PAGE  (wrapped with lifecycle watcher)
// ─────────────────────────────────────────────
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

  late AnimationController _logoController;
  late AnimationController _profileController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    ProfileService().updateStreak();

    _scrollController.addListener(() {
      final newOffset = _scrollController.offset;
      if ((newOffset - _scrollOffset).abs() > 5) {
        setState(() => _scrollOffset = newOffset);
      }
    });

    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _profileController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _logoController.dispose();
    _profileController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Wrap entire home in lifecycle watcher for auto-restart
    return AppLifecycleWatcher(
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    final isScrolled = _scrollOffset > 20;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: isScrolled
                ? (isDark
                    ? const Color(0xFF1A1A2E).withValues(alpha: 0.97)
                    : Colors.white.withValues(alpha: 0.95))
                : Colors.transparent,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: isScrolled
                ? (isDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
                : SystemUiOverlayStyle.light,
            leading: _AppBarIconButton(
              icon: Icons.menu_rounded,
              isScrolled: isScrolled,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: FadeTransition(
              opacity: _logoController,
              child: GestureDetector(
                onTap: () => _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue
                            .withValues(alpha: isScrolled ? 0.3 : 0.55),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text('RIZ',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Ubuntu',
                          fontStyle: FontStyle.italic,
                          fontSize: 20,
                          letterSpacing: 2)),
                ),
              ),
            ),
            actions: [
              _AppBarIconButton(
                icon: Icons.search_rounded,
                isScrolled: isScrolled,
                onTap: () => showSearch(
                    context: context, delegate: ExamSearchDelegate()),
              ),
              _AppBarIconButton(
                icon: Icons.notifications_outlined,
                isScrolled: isScrolled,
                onTap: _handleNotificationTap,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10, left: 2),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                          parent: _profileController,
                          curve: Curves.elasticOut)),
                  child: GestureDetector(
                    onTap: _navigateToProfile,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isScrolled
                            ? const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF1976D2)])
                            : null,
                        color: isScrolled
                            ? null
                            : Colors.white.withValues(alpha: 0.25),
                        border: Border.all(
                          color: isScrolled
                              ? Colors.transparent
                              : Colors.white.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isScrolled ? 0.15 : 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: isScrolled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                        child: const Icon(Icons.person,
                            color: Color(0xFF2196F3), size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildHeroSection(),
              RepaintBoundary(child: _buildStatsSection()),
              RepaintBoundary(child: _buildFeaturesSection()),
              const RepaintBoundary(child: CategoriesSection()),
              RepaintBoundary(child: _buildStudyResourcesSection()),
              RepaintBoundary(child: _buildMotivationalSection()),
              RepaintBoundary(child: _buildFooter()),
            ]),
          ),
        ],
      ),
      floatingActionButton: _scrollOffset > 500
          ? FloatingActionButton(
              onPressed: () => _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic),
              backgroundColor: const Color(0xFF2196F3),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  // ── All the section builders are identical to your original ──
  // (kept verbatim to avoid breaking anything)

  void _scrollToCategories() {
    final screenHeight = MediaQuery.of(context).size.height;
    _scrollController.animateTo((screenHeight * 0.75) + 900,
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOutCubic);
  }

  void _scrollToResources() {
    final screenHeight = MediaQuery.of(context).size.height;
    _scrollController.animateTo((screenHeight * 0.75) + 1200,
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOutCubic);
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Stack(children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                  'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=2070'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.blue.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOut,
                builder: (context, double value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)), child: child),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        border:
                            Border.all(color: Colors.orangeAccent, width: 2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text('🎯 YOUR SUCCESS STARTS HERE',
                          style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Ubuntu',
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Ace Government',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Ubuntu',
                            height: 1.1,
                            shadows: [
                              Shadow(blurRadius: 20, color: Colors.black87)
                            ])),
                    const Text('Sector Exams',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Ubuntu',
                            height: 1.1,
                            shadows: [
                              Shadow(blurRadius: 20, color: Colors.black87)
                            ])),
                    const SizedBox(height: 16),
                    const Text(
                      'Comprehensive preparation for TNPSC, UPSC, SSC, Banking & more',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Ubuntu',
                          fontStyle: FontStyle.italic,
                          height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    _buildCTAButton(
                        'Start Learning', Icons.rocket_launch_rounded),
                    const SizedBox(height: 12),
                    _buildCTAButton('Explore Resources', Icons.explore_rounded),
                  ],
                ),
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
            builder: (context, child) => Opacity(
              opacity: 0.7 - (_pulseController.value * 0.3),
              child: Column(children: [
                const Text('Scroll to explore',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'Ubuntu',
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 24 + (_pulseController.value * 4)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCTAButton(String text, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (text == 'Start Learning') _scrollToCategories();
          if (text == 'Explore Resources') _scrollToResources();
        },
        icon: Icon(icon, size: 20),
        label: Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu',
                letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.white, Colors.grey[50]!]),
      ),
      child: Column(children: [
        Text('Trusted Preparation Platform',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1976D2),
                fontFamily: 'Ubuntu')),
        const SizedBox(height: 40),
        _buildStatCard('1000+', 'Study Resources', Icons.library_books_rounded,
            Colors.purple),
        const SizedBox(height: 20),
        _buildStatCard(
            '500+', 'Practice Questions', Icons.quiz_rounded, Colors.orange),
      ]),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: isDark ? 0.05 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(width: 20),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontFamily: 'Ubuntu')),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontFamily: 'Ubuntu')),
          ],
        )),
      ]),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'title': 'Digital Flashcards',
        'desc': 'Smart adaptive learning',
        'icon': Icons.auto_awesome_rounded,
        'color': Colors.purple
      },
      {
        'title': "PYQ's",
        'desc': 'PYQ database',
        'icon': Icons.history_edu_rounded,
        'color': Colors.blue
      },
      {
        'title': 'Study Links',
        'desc': 'Organized materials',
        'icon': Icons.folder_special_rounded,
        'color': Colors.orange
      },
    ];
    final cardWidth = (MediaQuery.of(context).size.width - 56) / 2;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.center,
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)]),
      ),
      child: Column(children: [
        const Text('Powerful Features',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Ubuntu')),
        const SizedBox(height: 12),
        const Text('Everything you need to succeed in one place',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: Colors.white70, fontFamily: 'Ubuntu')),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: List.generate(
              features.length,
              (i) => _AnimatedFeatureCard(
                    delay: i * 200,
                    width: cardWidth,
                    title: features[i]['title'] as String,
                    desc: features[i]['desc'] as String,
                    icon: features[i]['icon'] as IconData,
                    color: features[i]['color'] as Color,
                  )),
        ),
      ]),
    );
  }

  Widget _buildStudyResourcesSection() => const StudyResourcesSection();

  Widget _buildMotivationalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF0D47A1)]),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orangeAccent, width: 2)),
          child: const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.auto_stories_rounded,
                  size: 40, color: Color(0xFF2196F3))),
        ),
        const SizedBox(height: 24),
        const Icon(Icons.format_quote_rounded,
            size: 40, color: Colors.orangeAccent),
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
              height: 1.5),
        ),
        const SizedBox(height: 16),
        Text('- Dr. APJ Abdul Kalam',
            style: TextStyle(
                color: Colors.orangeAccent.withValues(alpha: 0.95),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu',
                fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: const Color(0xFF1A1A1A),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('RIZ',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  letterSpacing: 2,
                  fontFamily: 'Ubuntu',
                  fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 20),
        const Text('Empowering aspirants to achieve their dreams',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white70, fontSize: 14, fontFamily: 'Ubuntu')),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _socialIcon(Icons.facebook_rounded),
          const SizedBox(width: 16),
          _socialIcon(Icons.telegram_rounded),
          const SizedBox(width: 16),
          _socialIcon(Icons.email_rounded),
        ]),
        const SizedBox(height: 24),
        Container(height: 1, width: 200, color: Colors.white24),
        const SizedBox(height: 20),
        Text('© 2026 RIZ Learning Hub',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontFamily: 'Ubuntu')),
        const SizedBox(height: 8),
        const Text('Made with ❤️ for every aspiring achiever',
            style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu')),
      ]),
    );
  }

  Widget _socialIcon(IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
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
              colors: [Color(0xFF2196F3), Color(0xFF1565C0)]),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('RIZ',
                      style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          fontFamily: 'Ubuntu',
                          fontStyle: FontStyle.italic)),
                ),
                const SizedBox(width: 12),
                const Text('Learning Hub',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Ubuntu')),
              ]),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
                child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(Icons.home_rounded, 'Home', () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()));
                }),
                _drawerItem(Icons.style_rounded, 'Digital Flashcards', () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DigitalFlashcardsScreen()));
                }),
                _drawerItem(Icons.history_edu_rounded, "PYQ's", () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PYQsScreen()));
                }),
                _drawerItem(Icons.link_rounded, 'Study Links', () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StudyVaultScreen()));
                }),
                _drawerItem(Icons.article_rounded, 'Current Affairs', () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CurrentAffairsScreen()));
                }),
                _drawerItem(Icons.calculate_rounded, 'Quantitative Aptitude',
                    () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QuantitativeAptitudeScreen()));
                }),
                _drawerItem(Icons.public_rounded, 'General Knowledge', () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GeneralKnowledgeScreen()));
                }),
                const Divider(
                    color: Colors.white30,
                    height: 32,
                    indent: 20,
                    endIndent: 20),
                _drawerItem(Icons.settings_rounded, 'Settings', () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()));
                }),
                _drawerItem(Icons.help_outline_rounded, 'Help & Support', () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()));
                }),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_rounded,
                        color: Colors.orange, size: 22),
                    title: const Text('Test Notification',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            fontFamily: 'Ubuntu')),
                    onTap: () async {
                      Navigator.pop(context);
                      final service = NotificationService();
                      final granted = await service.requestPermission();
                      if (!granted) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('❌ Notifications not permitted',
                                      style: TextStyle(fontFamily: 'Ubuntu')),
                                  backgroundColor: Colors.red));
                        }
                        return;
                      }
                      await service.showTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('✅ Notification sent!',
                                    style: TextStyle(fontFamily: 'Ubuntu')),
                                backgroundColor: Colors.green));
                      }
                    },
                  ),
                ),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15,
                fontFamily: 'Ubuntu')),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white54, size: 14),
        onTap: onTap,
      ),
    );
  }

  Future<void> _handleNotificationTap() async {
    final notificationService = NotificationService();
    bool isEnabled = await notificationService.areNotificationsEnabled();
    if (!isEnabled) {
      bool granted = await notificationService.requestPermission();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            granted ? '✅ Notifications enabled!' : '❌ Notifications denied',
            style: const TextStyle(fontFamily: 'Ubuntu')),
        backgroundColor: granted ? Colors.green : Colors.red,
      ));
    } else {
      _showNotificationSettings();
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('🔔 Notifications',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ubuntu')),
          const SizedBox(height: 16),
          const Text('✅ Notifications are enabled!',
              style: TextStyle(
                  fontSize: 16, color: Colors.green, fontFamily: 'Ubuntu')),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
              child: const Text('Settings',
                  style: TextStyle(fontFamily: 'Ubuntu')),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
              onPressed: () async {
                await NotificationService().disableNotifications();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Notifications disabled',
                        style: TextStyle(fontFamily: 'Ubuntu'))));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disable',
                  style: TextStyle(fontFamily: 'Ubuntu', color: Colors.white)),
            )),
          ]),
        ]),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }
}

// ── StudyResourcesSection, AnimatedResourceCard, feature cards,
//    _AppBarIconButton — all identical to your original file ──────

class StudyResourcesSection extends StatefulWidget {
  const StudyResourcesSection({super.key});
  @override
  State<StudyResourcesSection> createState() => _StudyResourcesSectionState();
}

class _StudyResourcesSectionState extends State<StudyResourcesSection>
    with TickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation, _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction > 0.3 && !_isVisible) {
      setState(() => _isVisible = true);
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return VisibilityDetector(
      key: const Key('study-resources-section'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF16213E), const Color(0xFF1A1A2E)]
                  : [Colors.grey[50]!, Colors.white]),
        ),
        child: Column(children: [
          FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SlideTransition(
                      position: _slideAnimation,
                      child: Text('Latest Study Resources',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Ubuntu',
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1976D2)))))),
          const SizedBox(height: 32),
          AnimatedResourceCard(
              title: 'Current Affairs→',
              desc: 'Updated daily with latest events',
              stat: '✅',
              icon: Icons.article_rounded,
              color: Colors.blue,
              controller: _controller,
              delay: 0),
          const SizedBox(height: 16),
          AnimatedResourceCard(
              title: 'Quantitative Aptitude→',
              desc: 'Complete guide with shortcuts',
              stat: '✅',
              icon: Icons.calculate_rounded,
              color: Colors.purple,
              controller: _controller,
              delay: 150),
          const SizedBox(height: 16),
          AnimatedResourceCard(
              title: 'General Knowledge→',
              desc: 'Comprehensive GK database',
              stat: '✅',
              icon: Icons.public_rounded,
              color: Colors.orange,
              controller: _controller,
              delay: 300),
        ]),
      ),
    );
  }
}

class AnimatedResourceCard extends StatefulWidget {
  final String title, desc, stat;
  final IconData icon;
  final Color color;
  final AnimationController controller;
  final int delay;
  const AnimatedResourceCard(
      {super.key,
      required this.title,
      required this.desc,
      required this.stat,
      required this.icon,
      required this.color,
      required this.controller,
      required this.delay});
  @override
  State<AnimatedResourceCard> createState() => _AnimatedResourceCardState();
}

class _AnimatedResourceCardState extends State<AnimatedResourceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation, _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _cardController, curve: Curves.easeOutCubic));
    widget.controller.addListener(_onParentChange);
  }

  void _onParentChange() {
    if (widget.controller.value > 0.1 &&
        _cardController.status == AnimationStatus.dismissed) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _cardController.forward();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onParentChange);
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ProfileService().trackResourceAccessed();
              Widget screen;
              if (widget.title.contains('Current Affairs')) {
                screen = const CurrentAffairsScreen();
              } else if (widget.title.contains('Quantitative')) {
                screen = const QuantitativeAptitudeScreen();
              } else {
                screen = const GeneralKnowledgeScreen();
              }
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => screen));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E30) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(widget.icon, color: widget.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'Ubuntu')),
                    const SizedBox(height: 4),
                    Text(widget.desc,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                            fontFamily: 'Ubuntu')),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(widget.stat,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.color,
                              fontFamily: 'Ubuntu')),
                    ),
                  ],
                )),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.grey[400]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedFeatureCard extends StatefulWidget {
  final int delay;
  final double width;
  final String title, desc;
  final IconData icon;
  final Color color;
  const _AnimatedFeatureCard(
      {required this.delay,
      required this.width,
      required this.title,
      required this.desc,
      required this.icon,
      required this.color});
  @override
  State<_AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<_AnimatedFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale, _slide, _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slide = Tween<double>(begin: 50.0, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.scale(
            scale: _scale.value,
            child: Transform.translate(
                offset: Offset(0, _slide.value),
                child: SizedBox(
                    width: widget.width,
                    child: _FeatureCardContent(
                        title: widget.title,
                        desc: widget.desc,
                        icon: widget.icon,
                        color: widget.color)))),
      ),
    );
  }
}

class _FeatureCardContent extends StatefulWidget {
  final String title, desc;
  final IconData icon;
  final Color color;
  const _FeatureCardContent(
      {required this.title,
      required this.desc,
      required this.icon,
      required this.color});
  @override
  State<_FeatureCardContent> createState() => _FeatureCardContentState();
}

class _FeatureCardContentState extends State<_FeatureCardContent> {
  bool _isPressed = false;

  void _navigate(BuildContext context) {
    Widget? screen;
    if (widget.title == 'Digital Flashcards')
      screen = const DigitalFlashcardsScreen();
    else if (widget.title == "PYQ's")
      screen = const PYQsScreen();
    else if (widget.title == 'Study Links') screen = const StudyVaultScreen();
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _navigate(context);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E30) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color:
                      Colors.black.withValues(alpha: _isPressed ? 0.05 : 0.1),
                  blurRadius: _isPressed ? 10 : 15,
                  offset: Offset(0, _isPressed ? 4 : 8))
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(widget.icon, color: widget.color, size: 32)),
            const SizedBox(height: 16),
            Text(widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Ubuntu')),
            const SizedBox(height: 8),
            Text(widget.desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontFamily: 'Ubuntu')),
          ]),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isScrolled;
  final VoidCallback onTap;
  const _AppBarIconButton(
      {required this.icon, required this.isScrolled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        padding: const EdgeInsets.all(6),
        decoration: isScrolled
            ? null
            : BoxDecoration(
                color: Colors.black.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
        child: Icon(icon,
            color: isScrolled ? Colors.black87 : Colors.white, size: 22),
      ),
    );
  }
}
