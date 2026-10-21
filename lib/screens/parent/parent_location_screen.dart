
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/tracking_service.dart';

class ParentLocationScreen extends StatefulWidget {
  final int deviceId;
  final String childName;

  const ParentLocationScreen({
    super.key,
    required this.deviceId,
    required this.childName,
  });

  @override
  State<ParentLocationScreen> createState() =>
      _ParentLocationScreenState();
}

class _ParentLocationScreenState
    extends State<ParentLocationScreen> {
  final TrackingService _service = TrackingService();

  late Future<Map<String, dynamic>> _locationFuture;

  static const Color blue = Color(0xFF168FE0);
  static const Color background = Color(0xFFF2F9FF);

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  void _loadLocation() {
    _locationFuture =
        _service.getLatestLocation(widget.deviceId);
  }

  void _refresh() {
    setState(_loadLocation);
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Chưa có dữ liệu';

    final raw = value.toString();
    final parsed = DateTime.tryParse(raw);

    if (parsed == null) return raw;

    // Backend không ghi múi giờ trong một số định dạng.
    // Giữ nguyên giờ nếu chuỗi không có Z hoặc offset.
    final date = parsed.isUtc
        ? parsed.toLocal()
        : parsed;

    String two(int number) =>
        number.toString().padLeft(2, '0');

    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }

  Future<void> _openMap(
      double latitude,
      double longitude,
      ) async {
    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': '$latitude,$longitude',
      },
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception('Không mở được Google Maps.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi mở bản đồ: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDCEFFD),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F4FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: blue),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 65,
              color: blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tải được vị trí',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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

  Widget _locationView(Map<String, dynamic> data) {
    final latitude = _asDouble(data['latitude']);
    final longitude = _asDouble(data['longitude']);

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return _errorView(
        'Backend chưa trả về tọa độ hợp lệ.',
      );
    }

    final recordedAt = _formatDate(data['recordedAt']);

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        try {
          await _locationFuture;
        } catch (_) {
          // FutureBuilder sẽ hiển thị thông báo lỗi.
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB9E5FF),
                  Color(0xFFE6F7FF),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: blue,
                  size: 70,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vị trí của ${widget.childName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vị trí được chia sẻ gần nhất',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          _infoCard(
            icon: Icons.smartphone,
            label: 'Thiết bị',
            value: '#${widget.deviceId}',
          ),

          const SizedBox(height: 12),

          _infoCard(
            icon: Icons.my_location,
            label: 'Vĩ độ',
            value: latitude.toStringAsFixed(6),
          ),

          const SizedBox(height: 12),

          _infoCard(
            icon: Icons.explore_outlined,
            label: 'Kinh độ',
            value: longitude.toStringAsFixed(6),
          ),

          const SizedBox(height: 12),

          _infoCard(
            icon: Icons.access_time_rounded,
            label: 'Thời gian Backend ghi nhận',
            value: recordedAt,
          ),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F2FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: blue,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đây là vị trí đã được chia sẻ '
                        'trước đó, không phải vị trí '
                        'trực tiếp theo thời gian thực.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () =>
                _openMap(latitude, longitude),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Xem trên Google Maps'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Cập nhật vị trí mới nhất'),
          ),
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
          'Vị trí thiết bị',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _locationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _errorView(snapshot.error!);
          }

          if (!snapshot.hasData) {
            return _errorView(
              'Không có dữ liệu vị trí.',
            );
          }

          return _locationView(snapshot.data!);
        },
      ),
    );
  }
}
