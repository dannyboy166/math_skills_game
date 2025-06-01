// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
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
        print(
            "AUTH DEBUG: Sign-in successful for user: ${result.user?.uid ?? 'null'}");
      }

      return result;
    } catch (e) {
      print("AUTH DEBUG: Error signing in with email: $e");
      throw e;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail(
      String email, String password, String displayName) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name
    await result.user!.updateDisplayName(displayName);

    return result;
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

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
      }

      return result;
    } catch (e) {
      print("Error signing in with Google: $e");
      throw e;
    }
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Generate a random nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in the user with Firebase
      final result = await _auth.signInWithCredential(oauthCredential);

      // If the user's name is available and not already set, update it
      if (result.user != null && 
          result.user!.displayName == null && 
          appleCredential.givenName != null) {
        final displayName = '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim();
        await result.user!.updateDisplayName(displayName);
      }

      // Force token refresh
      if (result.user != null) {
        await result.user!.getIdTokenResult(true);
      }

      return result;
    } catch (e) {
      print("Error signing in with Apple: $e");
      throw e;
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
      throw e;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // Helper method to generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // Helper method to generate SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}