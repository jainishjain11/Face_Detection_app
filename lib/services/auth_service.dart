import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  /// Register with email and password, then send OTP
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name.trim());

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email.trim(),
        'name': name.trim(),
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'faceDetectionSessions': 0,
      });

      // Generate and store OTP
      await _generateAndStoreOTP(email.trim());

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Login with email and password
  Future<UserCredential> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Check if email is verified in our system
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception('User profile not found. Please register again.');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Generate OTP and store in Firestore
  Future<void> _generateAndStoreOTP(String email) async {
    final otp = _generateOTP();
    final expiresAt = DateTime.now().add(
      Duration(minutes: AppConstants.otpExpiryMinutes),
    );

    await _firestore.collection('otps').doc(email).set({
      'otp': otp,
      'email': email,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'attempts': 0,
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // In a real app, send OTP via email using Cloud Functions / SendGrid
    // For demo: print OTP to console
    print('🔐 OTP for $email: $otp (expires in ${AppConstants.otpExpiryMinutes} min)');
  }

  /// Resend OTP
  Future<void> resendOTP(String email) async {
    await _generateAndStoreOTP(email.trim());
  }

  /// Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    final otpDoc = await _firestore.collection('otps').doc(email.trim()).get();

    if (!otpDoc.exists) {
      throw Exception(AppConstants.otpExpiryMinutes.toString());
    }

    final data = otpDoc.data()!;
    final attempts = (data['attempts'] as int?) ?? 0;

    // Rate limit
    if (attempts >= AppConstants.maxOtpAttempts) {
      throw Exception('max_attempts');
    }

    // Check expiry
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('expired');
    }

    // Increment attempts
    await _firestore.collection('otps').doc(email.trim()).update({
      'attempts': attempts + 1,
    });

    // Verify OTP
    if (data['otp'] != otp) {
      throw Exception('invalid_otp');
    }

    // Mark as verified
    await _firestore.collection('otps').doc(email.trim()).update({
      'verified': true,
    });

    // Update user's email verification status
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return true;
  }

  /// Check if user's email is verified in Firestore
  Future<bool> isEmailVerified(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    return doc.data()?['emailVerified'] ?? false;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete Firestore data
    await _firestore.collection('users').doc(user.uid).delete();
    await _firestore.collection('otps').doc(user.email).delete();

    // Delete auth user
    await user.delete();
  }

  /// Generate a 6-digit OTP
  String _generateOTP() {
    final random = Random.secure();
    return List.generate(
      AppConstants.otpLength,
      (_) => random.nextInt(10),
    ).join();
  }

  /// Handle Firebase auth exceptions with user-friendly messages
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('Password is too weak. Use at least 8 characters with numbers and special chars.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email address.');
      case 'user-not-found':
        return Exception('No account found with this email. Please register first.');
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
