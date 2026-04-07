import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers
  final _nameController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State Variables
  String _selectedBranch = "Computer Science";
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final List<String> _branches = [
    "Computer Science", "MCA", "IT", "Mechanical", "Civil", "Electrical"
  ];

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final enrollment = _enrollmentController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || enrollment.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.redAccent)
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create User in Firebase Auth
      UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Store Profile Data in Firestore
      // Added 'participatedEvents' as an empty list by default
      await FirebaseFirestore.instance.collection('students').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'enrollment': enrollment,
        'branch': _selectedBranch,
        'profilePic': "",
        'bio': "",
        'phoneNumber': "",
        'participatedEvents': [], // 👈 Crucial for the My Events tab logic
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Clear session so they must log in manually
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Registration Successful!\nPlease login to access Collexa Hub.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to LoginPage
              },
              child: const Text("Go to Login"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF0D47A1))
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))
              ),
              const SizedBox(height: 8),
              const Text("Join the academic ecosystem", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 35),

              _buildRegisterCard(),

              const SizedBox(height: 30),
              _buildLoginRedirect(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard() => Container(
    width: 450,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ]
    ),
    child: Column(
      children: [
        _buildInputField("FULL NAME", _nameController, Icons.person_outline, "e.g. Shubham Kumar"),
        const SizedBox(height: 20),
        _buildInputField("ENROLLMENT NO", _enrollmentController, Icons.badge_outlined, "e.g. 210203..."),
        const SizedBox(height: 20),

        // Branch Selector
        const Align(
            alignment: Alignment.centerLeft,
            child: Text("BRANCH", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0D47A1)))
        ),
        const SizedBox(height: 10),
        _buildBranchDropdown(),

        const SizedBox(height: 20),
        _buildInputField("COLLEGE EMAIL", _emailController, Icons.email_outlined, "name@university.edu"),
        const SizedBox(height: 20),
        _buildPasswordField(),

        const SizedBox(height: 35),
        _buildRegisterButton(),
      ],
    ),
  );

  Widget _buildBranchDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(15)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedBranch,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0D47A1)),
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 15),
        items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
        onChanged: (val) => setState(() => _selectedBranch = val ?? "Computer Science"),
      ),
    ),
  );

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, String hint) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0D47A1))),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(15)),
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF0D47A1), size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18)
          ),
        ),
      ),
    ],
  );

  Widget _buildPasswordField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("PASSWORD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0D47A1))),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(15)),
        child: TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0D47A1), size: 20),
            hintText: "••••••••",
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildRegisterButton() => SizedBox(
    width: double.infinity, height: 60,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
      ),
      onPressed: _isLoading ? null : _handleRegister,
      child: _isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("Register", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    ),
  );

  Widget _buildLoginRedirect() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Text("Login", style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
      ),
    ],
  );
}