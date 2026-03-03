import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);

    try {
      await _authService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder(
        stream: _firestoreService.getUserProfileStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (data?['name'] as String? ?? user?.displayName ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  data?['name'] ?? user?.displayName ?? 'User',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Verification status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (data?['emailVerified'] == true
                            ? AppColors.success
                            : AppColors.warning)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data?['emailVerified'] == true
                            ? Icons.verified
                            : Icons.pending_outlined,
                        size: 14,
                        color: data?['emailVerified'] == true
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data?['emailVerified'] == true
                            ? 'Verified'
                            : 'Pending Verification',
                        style: TextStyle(
                          color: data?['emailVerified'] == true
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Stats card
                _buildStatsCard(data),
                const SizedBox(height: 32),

                // Info fields
                _buildInfoField(
                    'Full Name', data?['name'] ?? user?.displayName ?? '-'),
                const SizedBox(height: 12),
                _buildInfoField('Email', user?.email ?? '-'),
                const SizedBox(height: 12),
                _buildInfoField(
                  'Member Since',
                  data?['createdAt'] != null
                      ? _formatDate(
                          (data!['createdAt'] as dynamic).toDate())
                      : '-',
                ),
                const SizedBox(height: 40),

                // Logout
                CustomButton(
                  label: AppStrings.logout,
                  onPressed: _logout,
                  isLoading: _isLoading,
                  icon: Icons.logout_rounded,
                  backgroundColor: AppColors.darkCard,
                ),
                const SizedBox(height: 12),

                // Delete account
                CustomOutlinedButton(
                  label: AppStrings.deleteAccount,
                  onPressed: _isLoading ? null : _deleteAccount,
                  icon: Icons.delete_outline,
                  borderColor: AppColors.error,
                  foregroundColor: AppColors.error,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkDivider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${data?['faceDetectionSessions'] ?? 0}',
            'Sessions',
            Icons.videocam_outlined,
          ),
          _buildDivider(),
          _buildStatItem(
            'ML Kit',
            'Engine',
            Icons.psychology_outlined,
          ),
          _buildDivider(),
          _buildStatItem(
            'Active',
            'Status',
            Icons.circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: AppColors.darkDivider);
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkDivider),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
