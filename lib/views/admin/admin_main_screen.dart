import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/add_event_page.dart';
import '../../models/event_model.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const AddEventPage(),
    const StudentListTab(),
    const UpcomingEventsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF0D47A1),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Create"),
            BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: "Students"),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: "Feed"),
          ],
        ),
      ),
    );
  }
}
class StudentListTab extends StatefulWidget {
  const StudentListTab({super.key});

  @override
  State<StudentListTab> createState() => _StudentListTabState();
}
PreferredSizeWidget _buildAdminAppBar(String title) {
  return AppBar(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
    backgroundColor: Colors.white,
    elevation: 0,
    actions: [
      Builder(
        builder: (context) => IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Admin Logout"),
                content: const Text("Close admin session?"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Navigator.pushNamedAndRemoveUntil is better if routes are set in main.dart
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
        ),
      ),
      const SizedBox(width: 10),
    ],
  );
}
class _StudentListTabState extends State<StudentListTab> {
  String selectedBranch = "Computer Science";
  final List<String> branches = ["Computer Science", "MCA", "IT", "Mechanical", "Civil", "Electrical"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: _buildAdminAppBar("Student Directory"),
      body: Column(
        children: [
          // Styled Filter Section
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: DropdownButtonFormField<String>(
              value: selectedBranch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.filter_list, color: Color(0xFF0D47A1)),
                labelText: "Filter by Course",
                filled: true,
                fillColor: const Color(0xFFF1F3F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) => setState(() => selectedBranch = val!),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('students').where('branch', isEqualTo: selectedBranch).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var students = snapshot.data!.docs;

                if (students.isEmpty) return const Center(child: Text("No students found in this branch"));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var data = students[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
                          child: Text(data['name'][0], style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("ID: ${data['enrollment']}"),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UpcomingEventsTab extends StatelessWidget {
  const UpcomingEventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: _buildAdminAppBar("Event Analytics"),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          List<EventModel> events = snapshot.data!.docs.map((doc) => EventModel.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              double progress = event.seatsFilled / event.passLimit;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(event.category.toUpperCase(), style: TextStyle(color: Colors.amber[800], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const Icon(Icons.more_vert, size: 18),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(event.startDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: progress > 0.8 ? Colors.red : const Color(0xFF0D47A1),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${event.seatsFilled} Registered", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text("${event.passLimit} Capacity", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}