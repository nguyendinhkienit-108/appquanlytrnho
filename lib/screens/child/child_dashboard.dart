
import 'package:flutter/material.dart';

import '../../services/token_service.dart';
import '../login_screen.dart';
import 'child_location_screen.dart';
import 'motion_sensor_screen.dart';
import 'learning_assistant_screen.dart';
import '../parent/applimits_screen.dart';

class ChildDashboard extends StatelessWidget {
  final String fullName;

  const ChildDashboard({
    super.key,
    required this.fullName,
  });

  static const Color blue = Color(0xFF2797E5);
  static const Color background = Color(0xFFF2F9FF);

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

  Widget _featureCard(
      IconData icon,
      String title,
      String subtitle, {
        VoidCallback? onTap,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE4F4FF),
          child: Icon(
            icon,
            color: blue,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: onTap == null
              ? Colors.grey.shade300
              : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'ChildSafety Kids',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB9E5FF),
                  Color(0xFFE5F6FF),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.sentiment_satisfied_alt,
                  size: 70,
                  color: blue,
                ),
                const SizedBox(height: 12),
                Text(
                  'Xin chào, $fullName!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chào mừng đến với ChildSafety',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Tiện ích của em',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Chưa kết nối chức năng.
          _featureCard(
            Icons.timer_outlined,
            'Thời gian sử dụng',
            'Xem giới hạn ứng dụng',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppLimitsScreen(
                    deviceId: 2,
                    childName: 'quoc huy',
                  ),
                ),
              );
            },
          ),

          // Đã kết nối màn hình chia sẻ vị trí.
          _featureCard(
            Icons.location_on_outlined,
            'Chia sẻ vị trí',
            'Chủ động chia sẻ vị trí với gia đình',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ChildLocationScreen(),
                ),
              );
            },
          ),

          // Sẽ phát triển sau.

          _featureCard(
            Icons.directions_run,
            'Cảm biến chuyển động',
            'Xem dữ liệu chuyển động của thiết bị',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MotionSensorScreen(),
                ),
              );
            },
          ),


          // Sẽ phát triển sau.

          _featureCard(
            Icons.image_search,
            'Hỗ trợ học tập',
            'Nhận diện và dịch chữ trong ảnh',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LearningAssistantScreen(),
                ),
              );
            },
          ),

        ],
      ),
    );
  }
}
