import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'models/student_model.dart';
import 'models/seat_model.dart';
import 'models/availability_model.dart';
import 'models/payment_model.dart';
import 'models/history_month_model.dart';
import 'screens/home_screen.dart';
//import 'services/seat_initializer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'models/history_entry_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  Hive.registerAdapter(StudentModelAdapter());
  Hive.registerAdapter(SeatModelAdapter());
  Hive.registerAdapter(AvailabilityModelAdapter());
  Hive.registerAdapter(PaymentModelAdapter());
  Hive.registerAdapter(HistoryMonthModelAdapter());
  Hive.registerAdapter(HistoryEntryModelAdapter());

  await Hive.openBox<StudentModel>("studentsBox");
  await Hive.openBox<SeatModel>("seatsBox");
  await Hive.openBox<AvailabilityModel>("availabilityBox");
  await Hive.openBox<PaymentModel>("paymentsBox");
  await Hive.openBox<HistoryMonthModel>("historyBox");

  //await Hive.box<SeatModel>("seatsBox").clear();

  //await Hive.box<AvailabilityModel>("availabilityBox").clear();

  //await SeatInitializer.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginScreen()
          : const HomeScreen(),
    );
  }
}
