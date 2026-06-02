import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'models/student_model.dart';
import 'models/seat_model.dart';
import 'models/availability_model.dart';
import 'models/payment_model.dart';
import 'services/sync_service.dart';
import 'models/history_entry_model.dart';
import 'models/history_month_model.dart';
//import 'services/seat_initializer.dart';
import 'screens/login_screen.dart';
import 'services/expiry_service.dart';
import 'screens/lock_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();

  Hive.registerAdapter(StudentModelAdapter());
  Hive.registerAdapter(SeatModelAdapter());
  Hive.registerAdapter(AvailabilityModelAdapter());
  Hive.registerAdapter(PaymentModelAdapter());
  Hive.registerAdapter(HistoryEntryModelAdapter());
  Hive.registerAdapter(HistoryMonthModelAdapter());

  await Hive.openBox<StudentModel>("studentsBox");

  await Hive.openBox<SeatModel>("seatsBox");

  await Hive.openBox<AvailabilityModel>("availabilityBox");
  await Hive.openBox<PaymentModel>("paymentsBox");
  await Hive.openBox<HistoryMonthModel>("historyBox");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<void>? _postAuthInit;

  Future<void> _runPostAuthInit() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncEpoch = prefs.getInt('last_sync_epoch') ?? 0;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    const twelveHoursMs = 12 * 60 * 60 * 1000;

    if (lastSyncEpoch == 0 || nowEpoch - lastSyncEpoch > twelveHoursMs) {
      await SyncService.syncAll();
      await prefs.setInt(
        'last_sync_epoch',
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    await ExpiryService.checkExpiredStudents();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        _postAuthInit ??= _runPostAuthInit();
        return const LockScreen();
      },
    );
  }
}
