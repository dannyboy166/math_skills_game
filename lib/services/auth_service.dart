// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
/*
  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      // Force token refresh here too
      if (result.user != null) {
        await result.user!.getIdTokenResult(true);
      }

      return result;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }
*/


// In AuthService class
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
}
