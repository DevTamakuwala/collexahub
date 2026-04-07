import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class EventDetailsPage extends StatefulWidget {
  final EventModel event;
  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  bool _isProcessing = false;

  Future<void> _registerForEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final studentRef = FirebaseFirestore.instance.collection('students').doc(user.uid);
      final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.event.id);
      final regRef = FirebaseFirestore.instance.collection('registrations').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot studentDoc = await transaction.get(studentRef);
        DocumentSnapshot eventDoc = await transaction.get(eventRef);

        if (!studentDoc.exists) throw "Student profile not found!";
        if (!eventDoc.exists) throw "Event no longer exists!";

        final studentData = studentDoc.data() as Map<String, dynamic>;
        final eventData = eventDoc.data() as Map<String, dynamic>;

        List<dynamic> participated = studentData['participatedEvents'] ?? [];
        String studentBranch = studentData['branch'] ?? '';
        int freshSeatsFilled = (eventData['seatsFilled'] ?? 0).toInt();
        int limit = (eventData['passLimit'] ?? 0).toInt();

        if (participated.contains(widget.event.id)) throw "Already registered!";
        if (!widget.event.isOpenToAll && widget.event.hostingBranch != studentBranch) {
          throw "Only for $studentBranch students.";
        }
        if (freshSeatsFilled >= limit) throw "Event is now full!";

        transaction.update(eventRef, {'seatsFilled': FieldValue.increment(1)});
        transaction.update(studentRef, {
          'participatedEvents': FieldValue.arrayUnion([widget.event.id])
        });
        transaction.set(regRef, {
          'eventId': widget.event.id,
          'studentUid': user.uid,
          'studentName': studentData['name'] ?? 'Student',
          'registrationDate': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) _showSuccess();
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 80),
            const SizedBox(height: 20),
            const Text("You're In!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
            const SizedBox(height: 10),
            const Text("Your seat is successfully reserved.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Awesome", style: TextStyle(fontWeight: FontWeight.bold))))],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('events').doc(widget.event.id).snapshots(),
      builder: (context, snapshot) {
        int liveFilled = (snapshot.data?.get('seatsFilled') ?? widget.event.seatsFilled).toInt();
        int seatsLeft = widget.event.passLimit - liveFilled;
        bool isFull = seatsLeft <= 0;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- MODERN SLIVER APP BAR ---
                  SliverAppBar(
                    expandedHeight: 380,
                    pinned: true,
                    elevation: 0,
                    stretch: true,
                    backgroundColor: const Color(0xFF0D47A1),
                    // Back Button with Glass Effect
                    leading: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.black26,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(widget.event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
                      centerTitle: false,
                      background: Hero(
                        tag: widget.event.id,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(widget.event.imageUrl, fit: BoxFit.cover),
                            // Dark Gradient Overlay for readability
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- CONTENT SECTION ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(25, 30, 25, 150),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _categoryBadge(widget.event.category),
                              _seatBadge(seatsLeft, isFull),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Text(widget.event.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF2D3142), letterSpacing: -0.5)),
                          const SizedBox(height: 30),

                          // Venue and Date with Better UI
                          Row(
                            children: [
                              _iconDetail(Icons.location_on_rounded, "VENUE", widget.event.venue),
                              const Spacer(),
                              _iconDetail(Icons.calendar_today_rounded, "DATE", widget.event.startDate),
                              const Spacer(),
                            ],
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Divider(color: Color(0xFFF1F1F1), thickness: 1.5),
                          ),

                          const Text("Event Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                          const SizedBox(height: 15),
                          Text(
                            widget.event.description,
                            style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.8, letterSpacing: 0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // --- FLOATING ACTION BUTTON ---
              Positioned(
                bottom: 30,
                left: 25,
                right: 25,
                child: _buildFloatingButton(isFull),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.08), borderRadius: BorderRadius.circular(15)),
    child: Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
  );

  Widget _seatBadge(int left, bool full) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: full ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Row(
      children: [
        Icon(Icons.bolt_rounded, size: 16, color: full ? Colors.red : Colors.orange),
        const SizedBox(width: 4),
        Text(full ? "FULL" : "$left SEATS", style: TextStyle(color: full ? Colors.red : Colors.orange, fontWeight: FontWeight.w900, fontSize: 11)),
      ],
    ),
  );

  Widget _iconDetail(IconData icon, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [Icon(icon, size: 16, color: Colors.blue), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))]),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142))),
    ],
  );

  Widget _buildFloatingButton(bool isFull) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isFull ? Colors.grey : const Color(0xFF0D47A1)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _isProcessing || isFull ? null : _registerForEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFull ? Colors.grey.shade400 : const Color(0xFF0D47A1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
          isFull ? "REGISTRATION CLOSED" : "BOOK MY SPOT NOW",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
        ),
      ),
    );
  }
}