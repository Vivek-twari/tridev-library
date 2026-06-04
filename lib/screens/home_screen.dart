import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../services/expiry_service.dart';
import 'student_list_screen.dart';
import 'seat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = [const StudentListScreen(), const SeatScreen()];

  Future<void> initializeApp() async {
    try {
      await SyncService.syncAll();

      await ExpiryService.checkExpiredStudents();
    } catch (e) {
      debugPrint("Initialization Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sync failed: $e")));
    }
  }

  @override
  void initState() {
    super.initState();

    initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Students"),

          BottomNavigationBarItem(icon: Icon(Icons.chair), label: "Seats"),
        ],
      ),
    );
  }
}
