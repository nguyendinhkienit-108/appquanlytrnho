
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import 3 giao diện để kiểm thử
import 'screens/login_screen.dart';
import 'screens/child/child_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Đọc địa chỉ API từ file .env
  await dotenv.load(fileName: '.env');

  runApp(const ChildSafetyApp());
}

class ChildSafetyApp extends StatelessWidget {
  const ChildSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChildSafety',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F9FF),
        useMaterial3: true,
      ),

      // =================================
      // CHỌN MÀN HÌNH MUỐN TEST
      // =================================

      // 1. TEST ĐĂNG NHẬP / PARENT
     //home: const LoginScreen(),

      // 2. TEST CHILD
       home: const ChildDashboard(fullName: 'quoc huy'),
      //home: const ChildDashboard(fullName: 'phat'),
      //home: const ChildDashboard(fullName: 'khanh'),

      // 3. TEST ADMIN
       //home: const AdminDashboard(fullName: 'Admin Test'),
    );
  }
}
