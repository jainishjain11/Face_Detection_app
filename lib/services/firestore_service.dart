import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ──────────────── User Profile ────────────────

  /// Get current user's profile stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return _db.collection('users').doc(uid).snapshots();
  }

  /// Get user profile once
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    await _db.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ──────────────── Face Detection Sessions ────────────────

  /// Log a face detection session
  Future<void> logDetectionSession({
    required int facesDetected,
    required Duration sessionDuration,
    double? averageFps,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Add session document
    await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .add({
      'facesDetected': facesDetected,
      'sessionDurationSeconds': sessionDuration.inSeconds,
      'averageFps': averageFps,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Increment session counter on user profile
    await _db.collection('users').doc(uid).update({
      'faceDetectionSessions': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get user's session history
  Future<List<Map<String, dynamic>>> getSessionHistory({int limit = 20}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ──────────────── OTP ────────────────

  /// Get OTP document
  Future<Map<String, dynamic>?> getOtpData(String email) async {
    final doc = await _db.collection('otps').doc(email).get();
    return doc.data();
  }

  // ──────────────── Analytics ────────────────

  /// Log analytics event
  Future<void> logEvent(String eventName, [Map<String, dynamic>? params]) async {
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    await _db.collection('analytics').add({
      'event': eventName,
      'uid': uid,
      'params': params ?? {},
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
