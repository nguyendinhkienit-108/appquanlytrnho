import 'package:flutter/material.dart';
import '../../services/children_service.dart';

class ChildDetailScreen extends StatefulWidget {
  final int deviceId;

  const ChildDetailScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  final ChildrenService _service = ChildrenService();

  late Future<Map<String, dynamic>> _detailFuture;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    setState(() {
      _detailFuture = _service.getChildDetail(widget.deviceId);
    });
  }

  String _formatLastActive(String value) {
    if (value.isEmpty) return 'Chưa có dữ liệu';

    try {
      final dt = DateTime.parse(value).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');

      return '$day/$month/$year  $hour:$minute:$second';
    } catch (_) {
      return value.replaceAll('T', ' ');
    }
  }

  Future<void> _deleteDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa thiết bị này khỏi danh sách quản lý không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await _service.deleteChild(widget.deviceId);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.blue)..withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        title: const Text('Chi tiết thiết bị'),
        actions: [
          IconButton(
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
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
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadDetail,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final child = snapshot.data!;

          final childName =
              child['childName']?.toString() ?? 'Chưa có tên';

          final pairingCode =
              child['pairingCode']?.toString() ?? 'Chưa có';

          final parentId =
              child['parentId']?.toString() ?? 'Không xác định';

          final lastActiveRaw =
              child['lastActive']?.toString() ?? '';

          final isLocked = child['isLocked'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER CARD
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black..withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.blue..withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.smartphone,
                          size: 46,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        childName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Thiết bị #${widget.deviceId}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isLocked
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                          ),
                        ),
                        child: Text(
                          isLocked ? 'Đã khóa' : 'Chưa khóa',
                          style: TextStyle(
                            color: isLocked
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                _sectionTitle('Thông tin thiết bị'),

                _infoTile(
                  icon: Icons.qr_code_2,
                  title: 'Mã ghép nối',
                  value: pairingCode,
                  iconColor: Colors.deepPurple,
                ),
                _infoTile(
                  icon: Icons.person_outline,
                  title: 'ID phụ huynh',
                  value: parentId,
                  iconColor: Colors.orange,
                ),
                _infoTile(
                  icon: Icons.lock_outline,
                  title: 'Trạng thái khóa',
                  value: isLocked ? 'Đã khóa' : 'Chưa khóa',
                  iconColor: isLocked ? Colors.red : Colors.green,
                ),
                _infoTile(
                  icon: Icons.access_time,
                  title: 'Hoạt động gần nhất',
                  value: _formatLastActive(lastActiveRaw),
                  iconColor: Colors.blue,
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _isDeleting ? null : _deleteDevice,
                  icon: _isDeleting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.delete_outline),
                  label: Text(
                    _isDeleting ? 'Đang xóa...' : 'Xóa thiết bị',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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