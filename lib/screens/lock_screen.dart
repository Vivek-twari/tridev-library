import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../screens/home_screen.dart';
import '../services/auth_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    authenticate();
  }

  Future<void> authenticate() async {
    try {
      setState(() {
        isLoading = true;
      });

      final canCheck = await auth.canCheckBiometrics;

      if (!canCheck) {
        goHome();
        return;
      }
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Unlock Study Hall',

        biometricOnly: false,

        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        goHome();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void goHome() {
    Navigator.pushReplacement(
      context,

      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Container(
            width: 420,

            padding: const EdgeInsets.all(30),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(30),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),

                  blurRadius: 18,

                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  height: 100,
                  width: 100,

                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),

                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: const Icon(
                    Icons.fingerprint,

                    color: Colors.white,

                    size: 52,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "Unlock Study Hall",

                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Text(
                  "Biometric authentication required",

                  textAlign: TextAlign.center,

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),

                const SizedBox(height: 38),

                SizedBox(
                  width: double.infinity,

                  height: 58,

                  child: ElevatedButton(
                    onPressed: isLoading ? null : authenticate,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Unlock",

                            style: TextStyle(
                              fontSize: 18,

                              color: Colors.white,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: () async {
                    await AuthService.logout();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(context);
                  },

                  child: const Text("Logout"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
