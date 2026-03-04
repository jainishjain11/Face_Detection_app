import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          'Session History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFF30363D)),
        ),
      ),
      body: uid == null
          ? const Center(
              child: Text(
                'Not logged in',
                style: TextStyle(color: Color(0xFF8B949E)),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('sessions')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3D5AFE),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFFF5252), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load sessions',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final sessions = snapshot.data?.docs ?? [];

                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D5AFE).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF3D5AFE),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No sessions yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start a face scan to see your history here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final data =
                        sessions[index].data() as Map<String, dynamic>;
                    final facesDetected = data['facesDetected'] ?? 0;
                    final durationSec =
                        data['sessionDurationSeconds'] ?? 0;
                    final avgFps = data['averageFps'];
                    final timestamp = data['timestamp'] as Timestamp?;
                    final dateStr = timestamp != null
                        ? _formatDate(timestamp.toDate())
                        : 'Recent';
                    final timeStr = timestamp != null
                        ? _formatTime(timestamp.toDate())
                        : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: const Color(0xFF30363D)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF3D5AFE).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural,
                            color: Color(0xFF3D5AFE),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'Scan #${sessions.length - index}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              _Badge(
                                label:
                                    '$facesDetected ${facesDetected == 1 ? 'face' : 'faces'}',
                                color: const Color(0xFF00BFA5),
                              ),
                              const SizedBox(width: 6),
                              _Badge(
                                label: '${durationSec}s',
                                color: const Color(0xFFFF6D00),
                              ),
                              if (avgFps != null) ...[
                                const SizedBox(width: 6),
                                _Badge(
                                  label:
                                      '${avgFps.toStringAsFixed(1)} fps',
                                  color: const Color(0xFF7C4DFF),
                                ),
                              ],
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: Color(0xFF8B949E),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (timeStr.isNotEmpty)
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  color: Color(0xFF8B949E),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '$facesDetected ${facesDetected == 1 ? 'face' : 'faces'} detected in ${durationSec}s'),
                              backgroundColor: const Color(0xFF161B22),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
