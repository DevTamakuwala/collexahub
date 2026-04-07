import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import 'event_details_page.dart';

class MyEventsPage extends StatelessWidget {
  const MyEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("My Events", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
          bottom: const TabBar(
            indicatorColor: Color(0xFF0D47A1),
            indicatorWeight: 3,
            labelColor: Color(0xFF0D47A1),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(text: "UPCOMING"),
              Tab(text: "PAST"),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('students').doc(user?.uid).snapshots(),
          builder: (context, studentSnapshot) {
            if (!studentSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            List<dynamic> participatedIds = studentSnapshot.data?['participatedEvents'] ?? [];

            if (participatedIds.isEmpty) {
              return _buildEmptyState();
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where(FieldPath.documentId, whereIn: participatedIds)
                  .snapshots(),
              builder: (context, eventSnapshot) {
                if (!eventSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<EventModel> myEvents = eventSnapshot.data!.docs
                    .map((doc) => EventModel.fromFirestore(doc))
                    .toList();

                // Sort and Filter Logic
                DateTime now = DateTime.now();
                DateFormat format = DateFormat('dd MMM, yyyy');

                List<EventModel> upcoming = [];
                List<EventModel> past = [];

                for (var event in myEvents) {
                  try {
                    DateTime eventDate = format.parse(event.startDate);
                    if (eventDate.isAfter(now)) {
                      upcoming.add(event);
                    } else {
                      past.add(event);
                    }
                  } catch (e) {
                    upcoming.add(event);
                  }
                }

                return TabBarView(
                  children: [
                    _buildEventList(context, upcoming, isPast: false),
                    _buildEventList(context, past, isPast: true),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(BuildContext context, List<EventModel> events, {required bool isPast}) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          isPast ? "No past events yet." : "No upcoming registrations.",
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Extra bottom padding for Nav Bar
      itemCount: events.length,
      itemBuilder: (context, index) => _buildTicketCard(context, events[index], isPast),
    );
  }

  Widget _buildTicketCard(BuildContext context, EventModel event, bool isPast) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsPage(event: event))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Event Image
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      event.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Event Basic Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.category.toUpperCase(),
                        style: TextStyle(color: isPast ? Colors.grey : const Color(0xFF0D47A1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(event.venue, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Icon(
                    isPast ? Icons.check_circle_rounded : Icons.confirmation_number_rounded,
                    color: isPast ? Colors.green[300] : const Color(0xFF0D47A1),
                    size: 28,
                  ),
                ),
              ],
            ),
            // Dotted Separator Logic
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: List.generate(
                    20,
                        (i) => Expanded(
                      child: Container(
                        color: i % 2 == 0 ? Colors.transparent : Colors.grey[200],
                        height: 1,
                      ),
                    )),
              ),
            ),
            // Bottom Date/Time Info
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0D47A1)),
                      const SizedBox(width: 8),
                      Text(event.startDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D47A1))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPast ? Colors.grey[100] : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPast ? "COMPLETED" : "UPCOMING",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isPast ? Colors.grey : const Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.airplane_ticket_outlined, size: 100, color: Colors.grey[200]),
        const SizedBox(height: 20),
        const Text("No Event Tickets Found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        const Text("Register for events to see them here!", style: TextStyle(color: Colors.grey)),
      ],
    ),
  );
}