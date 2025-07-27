// lib/main.dart - Updated to include haptic service
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:number_ninja/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart'; // Import the new landing screen
import 'services/leaderboard_initializer.dart';
import 'services/haptic_service.dart'; // Import the haptic service
import 'services/crashlytics_navigation_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Firebase Crashlytics only in release mode
  if (kReleaseMode) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await SoundService().initialize();

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();

  // Initialize haptic service
  await HapticService().initialize();

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
  } catch (e, stackTrace) {
    // Report non-fatal error to Crashlytics only in release mode
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        fatal: false,
        information: ['Leaderboard initialization failed'],
      );
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Ninja',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // Define text themes that are kid-friendly
        textTheme: TextTheme(
          displayLarge: TextStyle(fontFamily: 'ComicSans'),
          displayMedium: TextStyle(fontFamily: 'ComicSans'),
          displaySmall: TextStyle(fontFamily: 'ComicSans'),
          headlineMedium: TextStyle(fontFamily: 'ComicSans'),
          titleLarge: TextStyle(fontFamily: 'ComicSans'),
          bodyLarge: TextStyle(fontFamily: 'ComicSans'),
          bodyMedium: TextStyle(fontFamily: 'ComicSans'),
        ),
      ),
      navigatorObservers: [CrashlyticsNavigationObserver()],
      home: _handleAuthState(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _handleAuthState() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in - set user info for Crashlytics only in release mode
          if (kReleaseMode) {
            final user = snapshot.data!;
            FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
            FirebaseCrashlytics.instance.setCustomKey('user_email', user.email ?? 'no_email');
            FirebaseCrashlytics.instance.setCustomKey('display_name', user.displayName ?? 'no_name');
            FirebaseCrashlytics.instance.setCustomKey('auth_provider', user.providerData.isNotEmpty ? user.providerData.first.providerId : 'unknown');
            FirebaseCrashlytics.instance.log('User authenticated: ${user.uid}');
          }
          
          return HomeScreen();
        }

        // User is not logged in - set anonymous tracking only in release mode
        if (kReleaseMode) {
          FirebaseCrashlytics.instance.setUserIdentifier('anonymous');
          FirebaseCrashlytics.instance.setCustomKey('user_email', 'anonymous');
          FirebaseCrashlytics.instance.setCustomKey('display_name', 'anonymous');
          FirebaseCrashlytics.instance.setCustomKey('auth_provider', 'none');
          FirebaseCrashlytics.instance.log('User not authenticated - showing landing screen');
        }
        
        // Return the landing screen instead of the login screen directly
        return LandingScreen();
      },
    );
  }
}
