import 'package:flutter/material.dart';
import 'home/home_page.dart';
import 'home/my_events_page.dart';
import 'profile/profile_page.dart';
import 'home/add_event_page.dart'; // Ensure this path is correct

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const Center(child: Text("Search Page")),
    const MyEventsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Extend body behind the FAB for a seamless look
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // --- THE FLOATING ACTION BUTTON ---
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const AddEventPage()),
      //     );
      //   },
      //   backgroundColor: const Color(0xFF0D47A1), // Your brand blue
      //   shape: const CircleBorder(), // Makes it perfectly round
      //   elevation: 8,
      //   child: const Icon(Icons.add, color: Colors.white, size: 30),
      // ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 75,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25), // Floating effect
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 0, "HOME"),
          _navItem(Icons.search_rounded, 1, "SEARCH"),
          _navItem(Icons.calendar_month_rounded, 2, "CALENDAR"),
          _navItem(Icons.person_rounded, 3, "PROFILE"),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade400,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}