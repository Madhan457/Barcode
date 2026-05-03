import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.user;
    final isDark = themeProvider.isDarkMode;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Quick Bill User';
    final email = user?.email ?? 'No email available';

    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService().getUserDataStream(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final totalBills = userData?['totalBills'] ?? 0;
        final totalRevenue = userData?['totalRevenue'] ?? 0.0;
        final totalItemsSold = userData?['totalItemsSold'] ?? 0;
        final upiId = userData?['upiId'] ?? 'Not Set';

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF111827), const Color(0xFF1f2937)]
                  : [const Color(0xFFf9fafb), const Color(0xFFdbeafe)],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF84CC16), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(48),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFFbfdbfe),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1f2937) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFe5e7eb),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            '$totalBills',
                            'Total Bills',
                            const Color(0xFF2563eb),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFe5e7eb),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            '₹${totalRevenue > 1000 ? (totalRevenue / 1000).toStringAsFixed(1) + 'K' : totalRevenue.toStringAsFixed(0)}',
                            'Revenue',
                            const Color(0xFF9333ea),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFe5e7eb),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            '$totalItemsSold',
                            'Items Sold',
                            const Color(0xFF10b981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1f2937) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFe5e7eb),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.qr_code_scanner,
                      title: 'UPI Payment',
                      subtitle: upiId,
                      color: const Color(0xFF2563eb),
                      onTap: () => _showUpiDialog(context, upiId),
                    ),
                    _buildSettingItem(
                      icon: isDark ? Icons.wb_sunny : Icons.nightlight_round,
                      title: 'Theme',
                      subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                      color: isDark ? Colors.yellow : const Color(0xFF2563eb),
                      onTap: themeProvider.toggleTheme,
                    ),
                    _buildSettingItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Enabled',
                      color: const Color(0xFF9333ea),
                      onTap: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      color: const Color(0xFF10b981),
                      onTap: () {
                        Navigator.pushNamed(context, '/help_support');
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Security',
                      color: const Color(0xFFf59e0b),
                      onTap: () {
                        Navigator.pushNamed(context, '/privacy_security');
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          await authProvider.signOut();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Logged out successfully'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.logout),
                  label: Text(
                    authProvider.isLoading ? 'Logging out...' : 'Logout',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Info
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '© 2026 Quick Bill',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showUpiDialog(BuildContext context, String currentUpi) {
    final controller = TextEditingController(
      text: currentUpi == 'Not Set' ? '' : currentUpi,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update UPI ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your UPI ID (e.g., user@upi)',
            labelText: 'UPI ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirestoreService().updateUpiId(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}
