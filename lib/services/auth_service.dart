import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final auth = FirebaseAuth.instance;

  static const adminEmail = "amit.m2196@gmail.com";

  static const adminPassword = "Amit@123";

  static Future<void> login() async {
    await auth.signInWithEmailAndPassword(
      email: adminEmail,

      password: adminPassword,
    );
  }

  static Future<void> logout() async {
    await auth.signOut();
  }
}
