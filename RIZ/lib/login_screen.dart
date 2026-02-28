import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;
import 'firebase_service.dart';
import 'main.dart'; // AppWithLoading

// ═══════════════════════════════════════════════════════════
// LOGIN SCREEN  — MARKS-app inspired
// Orbiting exam badges → RIZ center logo → tagline → CTA
// ═══════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Orbit animation ────────────────────────────────────
  late AnimationController _orbitCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeIn;

  // ── Form state ─────────────────────────────────────────
  bool _showForm = false; // false = landing, true = email form
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _rememberMe = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebase = FirebaseService();

  // Exam badges shown orbiting
  final List<_ExamBadge> _badges = [
    _ExamBadge('TNPSC', '🏛️', Color(0xFF1565C0)),
    _ExamBadge('UPSC', '🇮🇳', Color(0xFF0D47A1)),
    _ExamBadge('SSC', '📋', Color(0xFF1976D2)),
    _ExamBadge('Bank', '🏦', Color(0xFF1E88E5)),
    _ExamBadge('Rail', '🚂', Color(0xFF2196F3)),
    _ExamBadge('Def', '⭐', Color(0xFF42A5F5)),
    _ExamBadge('GK', '🌍', Color(0xFF1565C0)),
    _ExamBadge('Apt', '🧮', Color(0xFF1976D2)),
  ];

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _loadSavedEmail();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_email');
    if (saved != null && mounted) {
      setState(() {
        _emailCtrl.text = saved;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveOrClearEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe
        ? await prefs.setString('saved_email', _emailCtrl.text.trim())
        : await prefs.remove('saved_email');
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isLogin && _passwordCtrl.text != _confirmCtrl.text) {
      _showError('Passwords do not match');
      return;
    }
    await _saveOrClearEmail();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // ✅ Wrap in try/catch to swallow the PigeonUserDetails cast bug.
        // The bug: firebase_auth on some Android versions throws a internal
        // type cast error AFTER auth succeeds. The user IS logged in.
        // We catch it, then verify via currentUser / authStateChanges.
        try {
          await _auth
              .signInWithEmailAndPassword(
                  email: _emailCtrl.text.trim(), password: _passwordCtrl.text)
              .timeout(const Duration(seconds: 15));
        } catch (innerE) {
          // Check if it is the known Pigeon/List<Object?> cast bug
          final isPigeonBug = innerE.toString().contains('PigeonUserDetails') ||
              innerE.toString().contains('List<Object?>') ||
              innerE.runtimeType.toString() == '_TypeError';
          if (!isPigeonBug) rethrow; // real error — bubble up
          debugPrint(
              '⚠️ PigeonUserDetails cast bug caught — checking auth state...');
          // Wait briefly for auth state to settle
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } else {
        UserCredential? cred;
        try {
          cred = await _auth
              .createUserWithEmailAndPassword(
                  email: _emailCtrl.text.trim(), password: _passwordCtrl.text)
              .timeout(const Duration(seconds: 15));
        } catch (innerE) {
          final isPigeonBug = innerE.toString().contains('PigeonUserDetails') ||
              innerE.toString().contains('List<Object?>') ||
              innerE.runtimeType.toString() == '_TypeError';
          if (!isPigeonBug) rethrow;
          debugPrint(
              '⚠️ PigeonUserDetails cast bug on signup — checking auth state...');
          await Future.delayed(const Duration(milliseconds: 500));
        }
        // Update display name and profile using currentUser (cred may be null due to bug)
        final user = cred?.user ?? _auth.currentUser;
        if (user != null) {
          try {
            await user.updateDisplayName(_nameCtrl.text.trim());
          } catch (_) {}
          try {
            await _firebase.createUserProfile(
                name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim());
          } catch (e) {
            debugPrint('⚠️ Profile creation non-fatal: $e');
          }
        }
      }

      // ✅ Confirm auth succeeded by checking currentUser
      // (works even when PigeonUserDetails bug swallows the credential)
      final confirmedUser = _auth.currentUser;
      if (confirmedUser == null) {
        // Auth genuinely failed
        if (mounted) setState(() => _isLoading = false);
        _showError('Login failed. Please check your credentials.');
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppWithLoading()),
        (_) => false,
      );
    } on TimeoutException {
      if (mounted) setState(() => _isLoading = false);
      _showError('Connection timeout. Check your internet.');
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(_authError(e.code));
    } catch (e) {
      debugPrint('❌ Auth error type: ${e.runtimeType}');
      debugPrint('❌ Auth error: $e');
      if (mounted) setState(() => _isLoading = false);
      _showError('Login failed. Please try again.');
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'email-already-in-use':
        return 'Email already registered. Try logging in.';
      case 'weak-password':
        return 'Password too weak (min 6 characters)';
      case 'invalid-email':
        return 'Invalid email address';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Something went wrong. Try again.';
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: const TextStyle(fontFamily: 'Ubuntu', fontSize: 14))),
      ]),
      backgroundColor: const Color(0xFFD32F2F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: _showForm ? _buildForm() : _buildLanding(),
        ),
      ),
    );
  }

  // ── LANDING: orbit + tagline + CTA ──────────────────────
  Widget _buildLanding() {
    return Column(
      children: [
        const Spacer(flex: 1),

        // Orbit diagram
        SizedBox(
          height: 320,
          child: AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (_, __) {
              final angle = _orbitCtrl.value * 2 * math.pi;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer dashed ring
                  _DashedCircle(radius: 135, color: Colors.grey.shade300),
                  // Inner dashed ring
                  _DashedCircle(radius: 85, color: Colors.grey.shade200),

                  // Orbiting badges — outer ring
                  for (int i = 0; i < _badges.length; i++)
                    _orbitingBadge(
                      badge: _badges[i],
                      index: i,
                      total: _badges.length,
                      radius: i.isEven ? 135.0 : 88.0,
                      angle: angle,
                      counterRotate: true,
                    ),

                  // Center RIZ logo
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('RIZ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Ubuntu',
                            fontStyle: FontStyle.italic,
                            letterSpacing: 2,
                          )),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const Spacer(flex: 1),

        // Tagline
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: 'Ubuntu',
                color: Colors.black87,
                height: 1.25,
              ),
              children: [
                TextSpan(text: 'Welcome to the\nnew way to '),
                TextSpan(
                  text: 'Practice',
                  style: TextStyle(color: Color(0xFF2196F3)),
                ),
                TextSpan(text: ' & '),
                TextSpan(
                  text: 'Learn',
                  style: TextStyle(color: Color(0xFF2196F3)),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'TNPSC • UPSC • SSC • Banking • Railways • Defence',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Ubuntu',
              color: Colors.grey.shade500,
              letterSpacing: 0.3,
            ),
          ),
        ),

        const Spacer(flex: 2),

        // CTA button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _isLogin = true;
                _showForm = true;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text('Login to continue',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Ubuntu')),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => setState(() {
                _isLogin = false;
                _showForm = true;
              }),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Create account',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                      fontFamily: 'Ubuntu')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orbitingBadge({
    required _ExamBadge badge,
    required int index,
    required int total,
    required double radius,
    required double angle,
    required bool counterRotate,
  }) {
    final startAngle = (2 * math.pi / total) * index;
    final currentAngle = startAngle + angle;
    final x = math.cos(currentAngle) * radius;
    final y = math.sin(currentAngle) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        // counter-rotate so badge text stays upright
        angle: counterRotate ? -angle : 0,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: badge.color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
                color: badge.color.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(badge.emoji,
                  style: const TextStyle(fontSize: 18, height: 1)),
              Text(badge.label,
                  style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: badge.color,
                      fontFamily: 'Ubuntu',
                      letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  // ── EMAIL FORM ───────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back to landing
            GestureDetector(
              onTap: () => setState(() => _showForm = false),
              child: Row(children: [
                const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Color(0xFF2196F3)),
                const SizedBox(width: 6),
                Text(_isLogin ? 'Login' : 'Sign Up',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Ubuntu',
                        color: Colors.black87)),
              ]),
            ),
            const SizedBox(height: 6),
            Text(
              _isLogin
                  ? 'Welcome back! Enter your credentials'
                  : 'Create your free RIZ account',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontFamily: 'Ubuntu'),
            ),
            const SizedBox(height: 28),

            if (!_isLogin) ...[
              _field(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (v) => v!.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
            ],

            _field(
              controller: _emailCtrl,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  !v!.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),

            _field(
              controller: _passwordCtrl,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              toggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
            ),

            if (!_isLogin) ...[
              const SizedBox(height: 16),
              _field(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                toggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
              ),
            ],

            const SizedBox(height: 12),

            if (_isLogin)
              Row(children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Remember me',
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontSize: 14,
                        color: Colors.grey.shade600)),
              ]),

            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  disabledBackgroundColor:
                      const Color(0xFF2196F3).withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(_isLogin ? 'Login' : 'Create Account',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Ubuntu')),
              ),
            ),

            const SizedBox(height: 20),

            // Switch mode
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isLogin = !_isLogin;
                  _passwordCtrl.clear();
                  _confirmCtrl.clear();
                }),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontSize: 14,
                        color: Colors.grey.shade600),
                    children: [
                      TextSpan(
                          text: _isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? '),
                      TextSpan(
                        text: _isLogin ? 'Sign up' : 'Login',
                        style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
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
      validator: validator,
      style: const TextStyle(fontFamily: 'Ubuntu', fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontFamily: 'Ubuntu', color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: const Color(0xFF2196F3), size: 22),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade400,
                    size: 20),
                onPressed: toggleObscure)
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dashed circle painter
// ─────────────────────────────────────────────
class _DashedCircle extends StatelessWidget {
  final double radius;
  final Color color;
  const _DashedCircle({required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: _DashedCirclePainter(radius: radius, color: color),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final double radius;
  final Color color;
  _DashedCirclePainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashCount = 40;
    const dashAngle = (2 * math.pi) / dashCount;
    const gapFraction = 0.45;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < dashCount; i++) {
      final start = i * dashAngle;
      final end = start + dashAngle * (1 - gapFraction);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
          end - start, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.radius != radius || old.color != color;
}

class _ExamBadge {
  final String label, emoji;
  final Color color;
  const _ExamBadge(this.label, this.emoji, this.color);
}
