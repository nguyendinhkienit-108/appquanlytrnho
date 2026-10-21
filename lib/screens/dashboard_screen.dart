
import 'package:flutter/material.dart';
import '../services/token_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  final String fullName;

  const DashboardScreen({
    super.key,
    required this.role,
    required this.fullName,
  });

  Future<void> _logout(BuildContext context) async {
    await TokenService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String title;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'admin':
        title = 'Trang quản trị';
        icon = Icons.admin_panel_settings;
        break;
      case 'parent':
        title = 'Dashboard phụ huynh';
        icon = Icons.family_restroom;
        break;
      case 'child':
        title = 'Dashboard trẻ em';
        icon = Icons.child_care;
        break;
      default:
        title = 'Tài khoản chưa được phân quyền';
        icon = Icons.person_outline;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 90, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Xin chào, $fullName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Vai trò: $role',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
