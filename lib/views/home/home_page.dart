import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import 'event_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = "All Events";
  final List<String> categories = ["All Events", "Technical", "Cultural", "Sports", "Workshops"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE), // Soft modern white
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Collexa Hub", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), fontSize: 24)),
            Text("Explore Campus Events", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildCategorySelector(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedCategory == "All Events"
                  ? FirebaseFirestore.instance.collection('events').orderBy('createdAt', descending: true).snapshots()
                  : FirebaseFirestore.instance.collection('events').where('category', isEqualTo: selectedCategory).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return _buildEmptyState();

                List<EventModel> events = snapshot.data!.docs.map((doc) => EventModel.fromFirestore(doc)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: events.length,
                  itemBuilder: (context, index) => _buildModernEventCard(events[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW ATTRACTIVE CARD DESIGN ---
  Widget _buildModernEventCard(EventModel event) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsPage(event: event))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D47A1).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  child: Hero(
                    tag: event.id,
                    child: Image.network(
                      event.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.image)),
                    ),
                  ),
                ),
                // Category Tag
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.category.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoIcon(Icons.calendar_today_outlined, event.startDate),
                      const SizedBox(width: 20),
                      _infoIcon(Icons.location_on_outlined, event.venue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoIcon(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 14, color: Colors.blueAccent),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
    ],
  );

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSel = selectedCategory == categories[index];
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = categories[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF0D47A1) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSel
                    ? [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                    : [],
                border: Border.all(color: isSel ? Colors.transparent : Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: Text(
                categories[index],
                style: TextStyle(color: isSel ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 15),
        const Text("No upcoming events here", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  // --- LOGOUT LOGIC ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to exit Collexa Hub?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}