import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF111827), const Color(0xFF1f2937)]
                  : [const Color(0xFFf9fafb), const Color(0xFFdbeafe)],
            ),
          ),
        ),
      ),
      body: Container(
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
            _buildSectionHeader('Security'),
            _buildSecurityItem(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your login credentials',
              color: Colors.blue,
              onTap: () {},
              isDark: isDark,
            ),
            _buildSecurityItem(
              icon: Icons.fingerprint,
              title: 'Biometric Lock',
              subtitle: 'Use fingerprint or face ID to open app',
              color: Colors.teal,
              onTap: () {},
              isDark: isDark,
            ),
            _buildSecurityItem(
              icon: Icons.devices_other,
              title: 'Active Devices',
              subtitle: 'Manage devices where you are logged in',
              color: Colors.orange,
              onTap: () {},
              isDark: isDark,
              isLast: true,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Privacy'),
            _buildSecurityItem(
              icon: Icons.description_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our terms and data usage policy',
              color: Colors.purple,
              onTap: () {},
              isDark: isDark,
            ),
            _buildSecurityItem(
              icon: Icons.delete_forever_outlined,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account and data',
              color: Colors.red,
              onTap: () {},
              isDark: isDark,
              isLast: true,
            ),
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Your data is end-to-end encrypted',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : Colors.white,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : (title == 'Change Password' || title == 'Privacy Policy'
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.zero),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
