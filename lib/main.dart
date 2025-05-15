import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/leaderboard_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize the app
  runApp(const MyApp());

  // Initialize leaderboard data after app is running
  // This won't block the app startup
  _initializeLeaderboardData();
}

Future<void> _initializeLeaderboardData() async {
  try {
    // Wait a short time to let the app initialize first
    await Future.delayed(Duration(seconds: 2));

    // Only run once per app session
    if (!LeaderboardInitializer.hasInitialized()) {
      final initializer = LeaderboardInitializer();
      await initializer.initializeForCurrentUser();
      LeaderboardInitializer.markInitialized();
    }
  } catch (e) {
    print('Error initializing leaderboard data: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Skills Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _handleAuthState(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _handleAuthState() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("MAIN DEBUG: Auth state changed. Connection state: ${snapshot.connectionState}");
        print("MAIN DEBUG: Has data: ${snapshot.hasData}, User: ${snapshot.data?.uid ?? 'null'}");
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("MAIN DEBUG: Auth state is waiting");
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in
          print("MAIN DEBUG: User is logged in: ${snapshot.data!.uid}");
          return HomeScreen();
        }

        // User is not logged in
        print("MAIN DEBUG: User is NOT logged in, showing LoginScreen");
        return LoginScreen();
      },
    );
  }
}