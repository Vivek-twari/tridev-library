import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/expiry_service.dart';
import '../services/sync_service.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    initialize();
  }

  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;

    /// NOT LOGGED IN
    if (user == null) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      return;
    }

    try {
      /// SYNC
      await SyncService.syncAll();

      await ExpiryService.checkExpiredStudents();
    } catch (e) {
      debugPrint("Startup Error: $e");
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,

      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
