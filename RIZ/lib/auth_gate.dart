import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';

// ═══════════════════════════════════════════════════════════
// AUTH GATE
// Listens to Firebase Auth state stream.
// • If user is already logged in  → goes straight to ProfileScreen
// • If user is not logged in      → shows LoginSignupScreen
// • While Auth is initialising    → shows a small spinner
//
// Use this wherever you currently push to ProfileScreen or
// show LoginSignupScreen — it handles both cases automatically.
// ═══════════════════════════════════════════════════════════

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // authStateChanges fires immediately with the cached session —
      // no network call needed, so there's no delay on restart.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ── Still waiting for Auth to initialise ────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)),
            ),
          );
        }

        // ── User is logged in ────────────────────────────────────
        if (snapshot.hasData && snapshot.data != null) {
          return const ProfileScreen();
        }

        // ── Not logged in ────────────────────────────────────────
        return const LoginSignupScreen();
      },
    );
  }
}
