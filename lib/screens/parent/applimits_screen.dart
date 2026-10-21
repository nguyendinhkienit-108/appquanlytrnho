
import 'package:flutter/material.dart';
import '../../services/applimits_service.dart';

class AppLimitsScreen extends StatefulWidget {
  final int deviceId;
  final String childName;

  const AppLimitsScreen({
    super.key,
    required this.deviceId,
    required this.childName,
  });

  @override
  State<AppLimitsScreen> createState() => _AppLimitsScreenState();
}

class _AppLimitsScreenState extends State<AppLimitsScreen> {
  final AppLimitsService _service = AppLimitsService();

  late Future<List<Map<String, dynamic>>> _limitsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _limitsFuture = _service.getLimits(widget.deviceId);
    });
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int? _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  // FORM THÊM HOẶC SỬA
  Future<void> _showLimitForm({
    Map<String, dynamic>? limit,
  }) async {
    final editing = limit != null;

    final appNameController = TextEditingController(
      text: limit?['appName']?.toString() ?? '',
    );

    final packageController = TextEditingController(
      text: limit?['packageName']?.toString() ?? '',
    );

    final minutesController = TextEditingController(
      text: limit?['allowedMinutesPerDay']?.toString() ?? '60',
    );

    bool blocked = limit?['isBlocked'] == true;
    bool saving = false;

    // Dùng biến thay vì TextEditingController cho các
    // trường trong form, tránh dispose khi dialog chưa đóng.
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (saving) return;

              final appName = appNameController.text.trim();
              final packageName = packageController.text.trim();
              final minutes = int.tryParse(
                minutesController.text.trim(),
              );

              if (!editing &&
                  (appName.isEmpty || packageName.isEmpty)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Vui lòng nhập tên và package ứng dụng',
                    ),
                  ),
                );
                return;
              }

              if (minutes == null ||
                  minutes < 0 ||
                  minutes > 1440) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Số phút phải từ 0 đến 1440',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                if (editing) {
                  final id = _parseId(limit['limitId']);

                  if (id == null) {
                    throw Exception('Không tìm thấy limitId hợp lệ');
                  }

                  await _service.updateLimit(
                    limitId: id,
                    allowedMinutesPerDay: minutes,
                    isBlocked: blocked,
                  );
                } else {
                  await _service.createLimit(
                    deviceId: widget.deviceId,
                    appName: appName,
                    packageName: packageName,
                    allowedMinutesPerDay: minutes,
                    isBlocked: blocked,
                  );
                }

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext, true);
              } catch (e) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst('Exception: ', ''),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );

                setDialogState(() => saving = false);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  Icon(
                    editing ? Icons.edit_outlined : Icons.add_circle,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      editing ? 'Sửa giới hạn' : 'Thêm giới hạn',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: appNameController,
                      enabled: !editing && !saving,
                      decoration: const InputDecoration(
                        labelText: 'Tên ứng dụng',
                        hintText: 'Ví dụ: YouTube',
                        prefixIcon: Icon(Icons.apps),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: packageController,
                      enabled: !editing && !saving,
                      decoration: const InputDecoration(
                        labelText: 'Package Name',
                        hintText: 'com.google.android.youtube',
                        prefixIcon: Icon(Icons.code),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: minutesController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giới hạn (phút/ngày)',
                        prefixIcon: Icon(Icons.timer_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Chặn ứng dụng'),
                      subtitle: Text(
                        blocked
                            ? 'Trạng thái: chặn'
                            : 'Trạng thái: cho phép',
                      ),
                      value: blocked,
                      onChanged: saving
                          ? null
                          : (value) {
                        setDialogState(() => blocked = value);
                      },
                    ),
                    if (editing)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Backend hiện chỉ hỗ trợ sửa số phút '
                              'và trạng thái chặn.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(editing ? 'Lưu thay đổi' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );

    // Không dispose ngay khi dialog pop để tránh
    // xung đột vòng đời với widget TextField.
    // Controller sẽ được thay bằng cách quản lý riêng
    // khi tách form thành StatefulWidget.

    if (!mounted) return;

    if (result == true) {
      _message(editing
          ? 'Cập nhật giới hạn thành công'
          : 'Thêm giới hạn thành công');
      _refresh();
    }
  }

  // XÓA GIỚI HẠN
  Future<void> _deleteLimit(Map<String, dynamic> limit) async {
    final id = _parseId(limit['limitId']);

    if (id == null) {
      _message('Không tìm thấy limitId', error: true);
      return;
    }

    final name = limit['appName']?.toString() ?? 'ứng dụng này';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giới hạn?'),
        content: Text(
          'Bạn muốn xóa quy tắc giới hạn của $name?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteLimit(id);

      if (!mounted) return;

      _message('Đã xóa giới hạn');
      _refresh();
    } catch (e) {
      _message(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  // THẺ THỐNG KÊ
  Widget _statCard({
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // THẺ GIỚI HẠN ỨNG DỤNG
  Widget _limitCard(Map<String, dynamic> limit) {
    final name = limit['appName']?.toString() ?? 'Ứng dụng';
    final packageName =
        limit['packageName']?.toString() ?? 'Không có package';

    final minutes =
        limit['allowedMinutesPerDay']?.toString() ?? '0';

    final blocked = limit['isBlocked'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: Colors.blue,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      packageName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: blocked
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  blocked ? 'Đã chặn' : 'Cho phép',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: blocked
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Colors.blue,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '$minutes phút/ngày',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sửa',
                onPressed: () => _showLimitForm(limit: limit),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                tooltip: 'Xóa',
                onPressed: () => _deleteLimit(limit),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Giới hạn ứng dụng'),
        backgroundColor: const Color(0xFFF5F7FC),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () => _showLimitForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm giới hạn'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _limitsFuture,
        builder: (context, snapshot) {
          final limits = snapshot.data ?? [];

          final blockedCount = limits
              .where((item) => item['isBlocked'] == true)
              .length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.smartphone,
                            color: Colors.blue,
                            size: 36,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.childName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Thiết bị #${widget.deviceId}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _statCard(
                          icon: Icons.grid_view_rounded,
                          title: 'Ứng dụng',
                          value: '${limits.length}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          icon: Icons.block,
                          title: 'Đã chặn',
                          value: '$blockedCount',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 56,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _refresh,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (limits.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 70,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Chưa có giới hạn ứng dụng',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Nhấn Thêm giới hạn để bắt đầu',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16, 8, 16, 110,
                      ),
                      itemCount: limits.length,
                      itemBuilder: (context, index) {
                        return _limitCard(limits[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
