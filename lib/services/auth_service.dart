// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log('Attempting email sign-in for: $email');
      FirebaseCrashlytics.instance.setCustomKey('last_attempted_email', email);
      FirebaseCrashlytics.instance.setCustomKey('auth_method', 'email_password');
    }

    try {
      print("AUTH DEBUG: Starting signInWithEmail for $email");

      // Sign in with credentials - NO signOut beforehand
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
          "AUTH DEBUG: Sign-in successful for user: ${result.user?.uid ?? 'null'}");

      // Force refresh the token to ensure auth state is properly updated
      if (result.user != null) {
        await result.user!.getIdTokenResult(true);
        if (kReleaseMode) {
          FirebaseCrashlytics.instance
              .log('Email sign-in successful for: ${result.user!.uid}');
          FirebaseCrashlytics.instance.setCustomKey(
              'last_successful_auth', DateTime.now().toIso8601String());
        }
        print(
            "AUTH DEBUG: Sign-in successful for user: ${result.user?.uid ?? 'null'}");
      }

      return result;
    } catch (e) {
      print("AUTH DEBUG: Error signing in with email: $e");
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.log('Email sign-in failed: $e');
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          fatal: false,
          information: ['Email sign-in failed for: $email', 'Error: $e'],
        );
      }
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail(
      String email, String password, String displayName) async {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance
          .log('Attempting email registration for: $email');
      FirebaseCrashlytics.instance.setCustomKey('registration_email', email);
      FirebaseCrashlytics.instance
          .setCustomKey('registration_display_name', displayName);
    }

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user!.updateDisplayName(displayName);

      if (kReleaseMode) {
        FirebaseCrashlytics.instance
            .log('Email registration successful for: ${result.user!.uid}');
        FirebaseCrashlytics.instance
            .setCustomKey('last_registration', DateTime.now().toIso8601String());
      }

      return result;
    } catch (e) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.log('Email registration failed: $e');
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          fatal: false,
          information: [
            'Email registration failed for: $email',
            'Display name: $displayName',
            'Error: $e'
          ],
        );
      }
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log('Attempting Google sign-in');
      FirebaseCrashlytics.instance.setCustomKey('auth_method', 'google');
    }

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        if (kReleaseMode) {
          FirebaseCrashlytics.instance.log('Google sign-in cancelled by user');
        }
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final result = await _auth.signInWithCredential(credential);

      // Force token refresh here too
      if (result.user != null) {
        await result.user!.getIdTokenResult(true);
        if (kReleaseMode) {
          FirebaseCrashlytics.instance
              .log('Google sign-in successful for: ${result.user!.uid}');
          FirebaseCrashlytics.instance.setCustomKey(
              'last_successful_auth', DateTime.now().toIso8601String());
        }
      }

      return result;
    } catch (e) {
      print("Error signing in with Google: $e");
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.log('Google sign-in failed: $e');
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          fatal: false,
          information: ['Google sign-in failed', 'Error: $e'],
        );
      }
      rethrow;
    }
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log('Attempting Apple sign-in');
      FirebaseCrashlytics.instance.setCustomKey('auth_method', 'apple');
    }

    try {
      print('🍎 === APPLE SIGN-IN DEBUG START ===');

      // Generate a random nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      print('🍎 Generated rawNonce length: ${rawNonce.length}');
      print('🍎 Generated nonce hash: $nonce');

      // Request credential for the currently signed in Apple account
      print('🍎 Requesting Apple ID credential...');
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      print('🍎 Apple credential received successfully');
      print('🍎 Apple ID Token: ${appleCredential.identityToken}');
      print('🍎 Apple Auth Code: ${appleCredential.authorizationCode}');
      print('🍎 Apple Email: ${appleCredential.email}');
      print('🍎 Apple Given Name: ${appleCredential.givenName}');
      print('🍎 Apple Family Name: ${appleCredential.familyName}');
      print('🍎 Apple User ID: ${appleCredential.userIdentifier}');

      // Validate required fields
      if (appleCredential.identityToken == null) {
        throw Exception('Apple ID token is null');
      }

      print(
          '🍎 Identity token length: ${appleCredential.identityToken!.length}');
      print('🍎 Raw nonce for credential: $rawNonce');

      // Create an `OAuthCredential` from the credential returned by Apple
      print('🍎 Creating OAuth credential...');
      print('🍎 Using rawNonce: $rawNonce');
      print(
          '🍎 Using idToken length: ${appleCredential.identityToken!.length}');

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode, // ← Add this line
      );

      print('🍎 OAuth credential created successfully');
      print('🍎 OAuth credential provider: ${oauthCredential.providerId}');
      print(
          '🍎 OAuth credential sign-in method: ${oauthCredential.signInMethod}');

      // Sign in the user with Firebase
      print('🍎 Attempting Firebase sign-in with credential...');
      final result = await _auth.signInWithCredential(oauthCredential);

      print('🍎 Firebase sign-in successful!');
      print('🍎 User UID: ${result.user?.uid}');
      print('🍎 User email: ${result.user?.email}');
      print('🍎 User display name: ${result.user?.displayName}');

      // If the user's name is available and not already set, update it
      if (result.user != null &&
          result.user!.displayName == null &&
          appleCredential.givenName != null) {
        final displayName =
            '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
                .trim();
        print('🍎 Updating display name to: $displayName');
        await result.user!.updateDisplayName(displayName);
      }

      // Force token refresh
      if (result.user != null) {
        print('🍎 Refreshing ID token...');
        await result.user!.getIdTokenResult(true);
        if (kReleaseMode) {
          FirebaseCrashlytics.instance
              .log('Apple sign-in successful for: ${result.user!.uid}');
          FirebaseCrashlytics.instance.setCustomKey(
              'last_successful_auth', DateTime.now().toIso8601String());
        }
        print('🍎 Token refresh complete');
      }

      print('🍎 === APPLE SIGN-IN DEBUG END (SUCCESS) ===');
      return result;
    } catch (e) {
      print('🍎 === APPLE SIGN-IN DEBUG END (ERROR) ===');
      print('🍎 Error Type: ${e.runtimeType}');
      print('🍎 Error Message: $e');
      print('🍎 Stack Trace: ${StackTrace.current}');

      // Additional error analysis
      if (e.toString().contains('invalid-credential')) {
        print('🍎 INVALID CREDENTIAL ERROR DETECTED');
        print('🍎 This usually means:');
        print('🍎 1. Apple OAuth not configured in Firebase Console');
        print('🍎 2. Bundle ID mismatch between Xcode and Firebase');
        print('🍎 3. Apple Services ID configuration issue');
        print('🍎 4. Missing or incorrect Apple Team ID/Key ID');
      }

      if (kReleaseMode) {
        FirebaseCrashlytics.instance.log('Apple sign-in failed: $e');
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          fatal: false,
          information: ['Apple sign-in failed', 'Error: $e'],
        );
      }
      rethrow;
    }
  }

  // Enhanced sign out
  Future<void> signOut() async {
    try {
      // Capture user ID for logging before signing out
      final uid = _auth.currentUser?.uid;
      print("AUTH DEBUG: Starting sign-out for user: $uid");

      // Sign out from Google first
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print("Google sign out error (non-critical): $e");
      }

      // Sign out from Firebase
      await _auth.signOut();

      // Add a check to make sure sign out was successful
      if (_auth.currentUser != null) {
        print(
            "AUTH DEBUG: Warning - user still logged in after signOut, forcing another signOut");
        await Future.delayed(Duration(milliseconds: 100));
        await _auth.signOut();
      }

      print(
          "AUTH DEBUG: Sign-out completed, current user is now: ${_auth.currentUser?.uid ?? 'null'}");
    } catch (e) {
      print("AUTH DEBUG: Error during sign out: $e");
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          fatal: false,
          information: ['Sign-out failed'],
        );
      }
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // Check if the current user signed in with email/password
  bool get isEmailPasswordUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Check if user has password provider
    for (var info in user.providerData) {
      if (info.providerId == 'password') {
        return true;
      }
    }
    return false;
  }

  // Get the user's authentication provider
  String? get userAuthProvider {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // Return the first provider (most relevant one)
    if (user.providerData.isNotEmpty) {
      return user.providerData.first.providerId;
    }
    return null;
  }

  // Helper method to generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // Helper method to generate SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
