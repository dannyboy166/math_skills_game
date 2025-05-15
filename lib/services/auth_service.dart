// lib/services/auth_service.dart - Simple, reliable version

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
      // Clear any existing credentials first
      await _auth.signOut(); 
      
      // Sign in with new credentials
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in with email: $e');
      throw e;
    }
  }
  
  // Register with email and password
  Future<UserCredential> registerWithEmail(String email, String password, String displayName) async {
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }
  
  // Sign out - Simple, robust version
  Future<void> signOut() async {
    try {
      // Sign out from Google first
      await _googleSignIn.signOut().catchError((e) {
        print("Google sign out error (non-critical): $e");
      });
      
      // Then sign out from Firebase
      await _auth.signOut();
      
      print("Successfully signed out");
    } catch (e) {
      print("Error during sign out: $e");
      throw e;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}