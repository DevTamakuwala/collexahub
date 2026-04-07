import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../admin/admin_main_screen.dart';
import '../home/home_page.dart'; // Ensure this path is correct
import '../main_screen.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  bool _isLoading = false;
  bool _isPasswordVisible = false; // To toggle password visibility

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // 1. Sign in normally through Firebase
      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // 2. CHECK ROLE: If email is admin@gmail.com, go to Admin Panel
      if (email == "admin@gmail.com") {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminMainScreen()),
                (route) => false,
          );
        }
      } else {
        // Go to Student Main Screen
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center( // Centered for better desktop/web appearance
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              _buildLogoHeader(),
              const SizedBox(height: 40),
              _buildLoginCard(),
              const SizedBox(height: 30),
              _buildFooter(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader() => Column(
    children: [
      const Text(
          "Collexa Hub",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))
      ),
      const SizedBox(height: 6),
      Container(height: 4, width: 50, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2))),
    ],
  );

  Widget _buildLoginCard() => Container(
    width: 400, // Constrained width for web/large screens
    margin: const EdgeInsets.symmetric(horizontal: 25),
    padding: const EdgeInsets.all(35),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 25, spreadRadius: 8, offset: const Offset(0, 10))
      ],
    ),
    child: Column(
      children: [
        const Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        const SizedBox(height: 8),
        const Text("Access your academic ecosystem", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 35),

        // Email Field
        _buildInputField(
          label: "COLLEGE EMAIL",
          controller: _emailController,
          icon: Icons.email_outlined,
          hint: "shubham@university.edu",
        ),

        const SizedBox(height: 25),

        // Password Field
        _buildInputField(
          label: "PASSWORD",
          controller: _passwordController,
          icon: Icons.lock_outline,
          hint: "Enter your password",
          isPassword: true,
        ),

        const SizedBox(height: 35),
        _buildSignInButton(),

        const SizedBox(height: 30),


      ],
    ),
  );

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0D47A1), letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(15)),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? !_isPasswordVisible : false,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500), // Darker text
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF0D47A1), size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
                  : null,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 14), // Lighter hint
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
      ),
      onPressed: _isLoading ? null : _handleLogin,
      child: _isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );



  Widget _buildFooter() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text("New user? ", style: TextStyle(color: Colors.grey)),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
        child: const Text("Register", style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
      ),
    ],
  );
}