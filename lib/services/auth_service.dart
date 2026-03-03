import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Save user profile to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'subscription': 'free',
        'faceDetectionSessions': 0,
      });

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete Firestore data
    await _firestore.collection('users').doc(user.uid).delete();

    // Delete auth user
    await user.delete();
  }

  // Handle Firebase auth exceptions with user-friendly messages
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('Password is too weak. Use at least 6 characters.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email address.');
      case 'user-not-found':
        return Exception('No account found with this email. Please sign up first.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'invalid-email':
        return Exception('The email address is badly formatted.');
      case 'user-disabled':
        return Exception('This account has been disabled. Contact support.');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Check your internet connection.');
      default:
        return Exception(e.message ?? 'Authentication failed. Please try again.');
    }
  }
}
