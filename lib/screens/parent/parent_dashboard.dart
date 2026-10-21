import 'package:flutter/material.dart';

import '../../services/children_service.dart';
import '../../services/token_service.dart';
import '../login_screen.dart';
import 'applimits_screen.dart';
import 'child_detail_screen.dart';

import 'parent_location_screen.dart';

class ParentDashboard extends StatefulWidget {
  final int parentId;
  final String fullName;

  const ParentDashboard({
    super.key,
    required this.parentId,
    required this.fullName,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final ChildrenService _service = ChildrenService();

  late Future<dynamic> _kidsFuture;

  @override
  void initState() {
    super.initState();
    _kidsFuture = _service.getMyKids(widget.parentId);
  }

  void _refresh() {
    setState(() {
      _kidsFuture = _service.getMyKids(widget.parentId);
    });
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addChild() async {
    final childName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String name = '';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: const [
              Icon(Icons.person_add_alt_1, color: Colors.lightBlue),
              SizedBox(width: 10),
              Text('Thêm trẻ em'),
            ],
          ),
          content: TextFormField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Họ và tên trẻ em',
              hintText: 'Ví dụ: Nguyễn Văn A',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              name = value;
            },
            onFieldSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                Navigator.pop(dialogContext, trimmed);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.lightBlue,
              ),
              onPressed: () {
                if (name.trim().isEmpty) return;
                Navigator.pop(dialogContext, name.trim());
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (childName == null || childName.isEmpty) {
      return;
    }

    try {
      await _service.createChild(
        parentId: widget.parentId,
        childName: childName,
      );

      if (!mounted) return;

      _showMessage('Thêm trẻ em thành công');
      _refresh();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _openChildDetail(int deviceId) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChildDetailScreen(
          deviceId: deviceId,
        ),
      ),
    );

    if (!mounted) return;

    if (deleted == true) {
      _showMessage('Đã xóa thiết bị thành công');
    }

    _refresh();
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.lightBlue.shade50,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.lightBlue,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child) {
    final childName =
        child['childName']?.toString() ?? 'Chưa có tên';

    final deviceId = int.tryParse(
      child['deviceId']?.toString() ?? '',
    );

    final isLocked = child['isLocked'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.lightBlue.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.smartphone,
                  color: Colors.lightBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thiết bị #${deviceId ?? "N/A"}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isLocked ? 'Đã khóa' : 'Chưa khóa',
                  style: TextStyle(
                    color: isLocked
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link,
                        size: 18,
                        color: Colors.lightBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đã liên kết',
                        style: TextStyle(
                          color: Colors.lightBlue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [

              _buildActionButton(
                icon: Icons.location_on_outlined,
                label: 'Vị trí',
                onTap: deviceId == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentLocationScreen(
                        deviceId: deviceId,
                        childName: childName,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.access_time,
                label: 'Giới hạn',
                onTap: deviceId == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppLimitsScreen(
                        deviceId: deviceId,
                        childName: childName,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.settings_outlined,
                label: 'Chi tiết',
                onTap: deviceId == null
                    ? null
                    : () => _openChildDetail(deviceId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.lightBlue.shade100,
            Colors.lightBlue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.family_restroom,
              color: Colors.lightBlue,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ChildSafety',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Xin chào, ${widget.fullName}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Quản lý thiết bị của trẻ em một cách an toàn và dễ dàng.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      appBar: AppBar(
        title: const Text(
          'ChildSafety',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF4FAFD),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        onPressed: _addChild,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm trẻ em'),
      ),
      body: FutureBuilder<dynamic>(
        future: _kidsFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final kids = data is List ? data : [];

          final int totalKids = kids.length;
          final int lockedKids = kids
              .where((item) => item is Map && item['isLocked'] == true)
              .length;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _buildStatCard(
                      icon: Icons.devices_rounded,
                      title: 'Thiết bị',
                      value: '$totalKids',
                      color: Colors.lightBlue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.lock_outline,
                      title: 'Đã khóa',
                      value: '$lockedKids',
                      color: Colors.redAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Danh sách thiết bị trẻ em',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Theo dõi và quản lý các thiết bị đã liên kết',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 58,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Không tải được dữ liệu',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.lightBlue,
                                  ),
                                  onPressed: _refresh,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (data is! List) {
                        return const Center(
                          child: Text(
                            'Dữ liệu API không đúng định dạng',
                          ),
                        );
                      }

                      if (data.isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue.shade50,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.group_off_outlined,
                                    size: 46,
                                    color: Colors.lightBlue,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Chưa có trẻ em nào',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhấn "Thêm trẻ em" để bắt đầu quản lý thiết bị.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.lightBlue,
                                  ),
                                  onPressed: _addChild,
                                  icon: const Icon(Icons.person_add_alt_1),
                                  label: const Text('Thêm trẻ em'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];

                          if (item is! Map) {
                            return const SizedBox.shrink();
                          }

                          return _buildChildCard(
                            Map<String, dynamic>.from(item),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}