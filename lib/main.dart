import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'views/auth/login_page.dart';
import 'views/main_screen.dart'; // Your Student Main Screen
import 'views/admin/admin_main_screen.dart'; // Your Admin Main Screen
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CollexaHubApp());
}

class CollexaHubApp extends StatelessWidget {
  const CollexaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Collexa Hub',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0D47A1),
      ),

      // 🛠️ THE PERSISTENCE ENGINE
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. While checking for a saved session in the browser
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. If a session is found (User is logged in)
          if (snapshot.hasData && snapshot.data != null) {
            User user = snapshot.data!;

            // Check: Is this the Admin account?
            if (user.email == "admin@gmail.com") {
              return const AdminMainScreen();
            } else {
              // It's a regular student
              return const MainScreen();
            }
          }

          // 3. If no session is found, show Login
          return const LoginPage();
        },
      ),

      // Named routes for manual navigation (Logout etc.)
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainScreen(),
        '/admin': (context) => const AdminMainScreen(),
      },
    );
  }
}