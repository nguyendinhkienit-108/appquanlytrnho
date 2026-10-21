
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/tracking_service.dart';

class ChildLocationScreen extends StatefulWidget {
  const ChildLocationScreen({super.key});

  @override
  State<ChildLocationScreen> createState() =>
      _ChildLocationScreenState();
}

class _ChildLocationScreenState
    extends State<ChildLocationScreen> {
  final _deviceController = TextEditingController();
  final _service = TrackingService();

  Position? _position;
  bool _loading = false;
  String? _message;

  static const Color blue = Color(0xFF168FE0);
  static const Color background = Color(0xFFF2F9FF);

  @override
  void dispose() {
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _loading = true;
      _message = null;
      _position = null;
    });

    try {
      final enabled =
      await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception(
          'GPS đang tắt. Hãy bật Location trên Emulator.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Bạn chưa cấp quyền truy cập vị trí.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      setState(() {
        _position = position;
        _message = 'Đã lấy vị trí. Chưa gửi lên máy chủ.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message =
            e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _shareLocation() async {
    final deviceId =
    int.tryParse(_deviceController.text.trim());
    final position = _position;

    if (deviceId == null || deviceId <= 0) {
      setState(() {
        _message = 'Vui lòng nhập ID thiết bị hợp lệ.';
      });
      return;
    }

    if (position == null) {
      setState(() {
        _message = 'Hãy lấy vị trí trước khi gửi.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận chia sẻ vị trí'),
          content: Text(
            'Bạn muốn gửi vị trí hiện tại đến máy chủ '
                'cho thiết bị #$deviceId?\n\n'
                'Vĩ độ: ${position.latitude.toStringAsFixed(6)}\n'
                'Kinh độ: ${position.longitude.toStringAsFixed(6)}\n\n'
                'Đây là thao tác chia sẻ một lần.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Đồng ý gửi'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _loading = true;
      _message = 'Đang gửi vị trí...';
    });

    try {
      await _service.updateLocation(
        deviceId: deviceId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _message = 'Đã gửi vị trí thành công!';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message =
            e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDCEFFB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F4FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: blue),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
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
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Chia sẻ vị trí',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFBCE8FF),
                  Color(0xFFE3F5FF),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 66,
                  color: blue,
                ),
                SizedBox(height: 12),
                Text(
                  'Vị trí của em',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Em có thể chọn lấy vị trí và '
                      'chia sẻ với gia đình khi muốn.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _deviceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'ID thiết bị thử nghiệm',
              hintText: 'Ví dụ: 2',
              prefixIcon: const Icon(
                Icons.smartphone,
                color: blue,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chỉ dùng ID thiết bị bạn có quyền kiểm thử. '
                'Trong bản hoàn chỉnh, ID phải được Backend '
                'xác thực và liên kết với tài khoản trẻ.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 22),
          _infoCard(
            icon: Icons.my_location,
            title: 'Vĩ độ',
            value: _position == null
                ? 'Chưa có dữ liệu'
                : _position!.latitude.toStringAsFixed(6),
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.explore_outlined,
            title: 'Kinh độ',
            value: _position == null
                ? 'Chưa có dữ liệu'
                : _position!.longitude.toStringAsFixed(6),
          ),
          const SizedBox(height: 22),
          if (_message != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(_message!),
            ),
            const SizedBox(height: 16),
          ],
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loading ? null : _getLocation,
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Lấy vị trí hiện tại'),
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              padding: const EdgeInsets.all(17),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading || _position == null
                ? null
                : _shareLocation,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Chia sẻ vị trí một lần'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(17),
            ),
          ),
        ],
      ),
    );
  }
}
