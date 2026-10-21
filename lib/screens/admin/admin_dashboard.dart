
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/token_service.dart';
import '../login_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String fullName;

  const AdminDashboard({
    super.key,
    required this.fullName,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();

  late Future<Map<String, dynamic>> _future;

  static const Color blue = Color(0xFF198FE3);
  static const Color dark = Color(0xFF192D42);
  static const Color background = Color(0xFFF2F9FF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _adminService.getDashboardSummary();
  }

  Future<void> _refresh() async {
    setState(_load);

    try {
      await _future;
    } catch (_) {
      // FutureBuilder hiển thị lỗi bên dưới.
    }
  }

  Future<void> _logout() async {
    await TokenService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) return 'Chưa có thông tin';

    String two(int number) => number.toString().padLeft(2, '0');

    final local = date.isUtc ? date.toLocal() : date;

    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  Widget _statCard({
    required String label,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDEEFFB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2087B9)
                .withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF687D8F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final fullName =
        user['fullName']?.toString() ?? 'Chưa có tên';

    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'Unknown';
    final userId = user['userId']?.toString() ?? '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDEEFFB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: blue,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF728596),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'ID #$userId  •  ${_formatDate(user['createdAt'])}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF728596),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Color(0xFF157FC7),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final recentUsers =
    data['recentUsers'] is List
        ? data['recentUsers'] as List
        : <dynamic>[];

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB6E4FF),
                  Color(0xFFE3F5FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(27),
            ),
            child: Row(
              children: [
                Container(
                  width: 61,
                  height: 61,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: blue,
                    size: 35,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUẢN TRỊ HỆ THỐNG',
                        style: TextStyle(
                          color: Color(0xFF47748F),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Xin chào, ${widget.fullName}!',
                        style: const TextStyle(
                          color: dark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Tổng quan hoạt động ChildSafety',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF526E81),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Thống kê hệ thống',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Số liệu được cập nhật từ Backend',
            style: TextStyle(
              color: Color(0xFF728596),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _statCard(
                label: 'Tổng tài khoản',
                count: _number(data['totalUsers']),
                icon: Icons.groups_outlined,
                iconColor: blue,
                iconBackground: const Color(0xFFE0F3FF),
              ),
              _statCard(
                label: 'Phụ huynh',
                count: _number(data['totalParents']),
                icon: Icons.family_restroom,
                iconColor: const Color(0xFF1C9B91),
                iconBackground: const Color(0xFFE0F8F2),
              ),
              _statCard(
                label: 'Nhân viên',
                count: _number(data['totalStaff']),
                icon: Icons.support_agent,
                iconColor: const Color(0xFF8364D9),
                iconBackground: const Color(0xFFF0EBFF),
              ),
              _statCard(
                label: 'Thiết bị trẻ em',
                count: _number(
                  data['totalChildrenDevices'],
                ),
                icon: Icons.smartphone,
                iconColor: const Color(0xFF3E91D3),
                iconBackground: const Color(0xFFE2F2FF),
              ),
              _statCard(
                label: 'Tổng cảnh báo',
                count: _number(data['totalAlerts']),
                icon: Icons.notifications_active_outlined,
                iconColor: const Color(0xFFEA8953),
                iconBackground: const Color(0xFFFFF1E7),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Người dùng gần đây',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${recentUsers.length} người',
                  style: const TextStyle(
                    color: blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recentUsers.isEmpty)
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'Chưa có dữ liệu người dùng.',
                ),
              ),
            )
          else
            ...recentUsers.whereType<Map>().map(
                  (item) => _userCard(
                Map<String, dynamic>.from(item),
              ),
            ),
          const SizedBox(height: 12),
        ],
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
          'ChildSafety Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: blue,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: blue,
                      size: 60,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Không tải được Admin Dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return const Center(
              child: Text('Không có dữ liệu thống kê.'),
            );
          }

          return _buildContent(data);
        },
      ),
    );
  }
}
