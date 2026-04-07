import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  void _updateProfile() async {
    try {
      await FirebaseFirestore.instance.collection('students').doc(user!.uid).update({
        'bio': _bioController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      // Custom AppBar style
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_note, color: Colors.white),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('students').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;

          // Only sync controllers if NOT currently typing
          if (!_isEditing) {
            _bioController.text = data['bio'] ?? "";
            _phoneController.text = data['phoneNumber'] ?? "";
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(data),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                  child: Column(
                    children: [
                      _buildInfoSection(data),
                      const SizedBox(height: 25),
                      _buildEditableSection(),
                      const SizedBox(height: 40),
                      if (_isEditing) _buildSaveButton(),
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- HEADER WITH GRADIENT ---
  Widget _buildHeader(Map<String, dynamic> data) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0D47A1),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
        Positioned(
          top: 40,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFF1F3F6),
              child: Text(
                data['name'] != null ? data['name'][0].toUpperCase() : "?",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- STUDENT DETAILS CARD ---
  Widget _buildInfoSection(Map<String, dynamic> data) {
    return Column(
      children: [
        const SizedBox(height: 50),
        Text(data['name'] ?? "Student Name", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        Text(data['email'] ?? "email@university.edu", style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _badge(Icons.school, data['branch'] ?? "Branch"),
            const SizedBox(width: 10),
            _badge(Icons.badge, data['enrollment'] ?? "Enrollment"),
          ],
        ),
      ],
    );
  }

  // --- EDITABLE FIELDS CARD ---
  Widget _buildEditableSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, spreadRadius: 5)],
      ),
      child: Column(
        children: [
          _customTextField("About Me / Bio", _bioController, Icons.info_outline, maxLines: 3),
          const Divider(height: 40),
          _customTextField("Phone Number", _phoneController, Icons.phone_android_outlined),
        ],
      ),
    );
  }

  Widget _customTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0D47A1), letterSpacing: 1)),
        TextField(
          controller: controller,
          enabled: _isEditing,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: _isEditing ? const Color(0xFF0D47A1) : Colors.grey),
            border: InputBorder.none,
            hintText: "Click edit to add info...",
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 15),
    child: ElevatedButton(
      onPressed: () {
        _updateProfile();
        setState(() => _isEditing = false);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D47A1),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildLogoutButton() => TextButton.icon(
    onPressed: () async {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    },
    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
    label: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
  );

  Widget _badge(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0D47A1)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
      ],
    ),
  );
}