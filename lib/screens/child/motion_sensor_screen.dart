
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MotionSensorScreen extends StatefulWidget {
  const MotionSensorScreen({super.key});

  @override
  State<MotionSensorScreen> createState() =>
      _MotionSensorScreenState();
}

class _MotionSensorScreenState
    extends State<MotionSensorScreen> {
  StreamSubscription<UserAccelerometerEvent>? _subscription;

  double _x = 0;
  double _y = 0;
  double _z = 0;
  double _magnitude = 0;

  bool _isListening = false;
  bool _hasData = false;
  String? _error;
  DateTime? _lastUpdate;

  static const Color blue = Color(0xFF168FE0);
  static const Color background = Color(0xFFF2F9FF);

  String get _motionStatus {
    if (!_hasData) return 'Chưa có dữ liệu';

    // Ngưỡng đơn giản để minh họa, không phải kết luận
    // về hoạt động thể chất hay an toàn của người dùng.
    if (_magnitude < 0.5) {
      return 'Ít chuyển động';
    }
    if (_magnitude < 2.0) {
      return 'Chuyển động nhẹ';
    }
    return 'Chuyển động rõ';
  }

  void _startListening() {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _hasData = false;
      _error = null;
      _lastUpdate = null;
      _x = 0;
      _y = 0;
      _z = 0;
      _magnitude = 0;
    });

    _subscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(
          (event) {
        if (!mounted || !_isListening) return;

        // Giới hạn số lần vẽ lại màn hình.
        final now = DateTime.now();
        if (_lastUpdate != null &&
            now.difference(_lastUpdate!).inMilliseconds < 150) {
          return;
        }

        final magnitude = sqrt(
          event.x * event.x +
              event.y * event.y +
              event.z * event.z,
        );

        setState(() {
          _lastUpdate = now;
          _hasData = true;

          _x = event.x;
          _y = event.y;
          _z = event.z;
          _magnitude = magnitude;
        });
      },
      onError: (Object error) {
        if (!mounted) return;

        _subscription?.cancel();
        _subscription = null;

        setState(() {
          _isListening = false;
          _error = 'Không đọc được cảm biến: $error';
        });
      },
      cancelOnError: true,
    );
  }

  Future<void> _stopListening() async {
    final subscription = _subscription;
    _subscription = null;

    await subscription?.cancel();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Widget _axisCard(String axis, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFDCEFFD),
          ),
        ),
        child: Column(
          children: [
            Text(
              axis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: blue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'm/s²',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: blue),
          ),
          const SizedBox(width: 14),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Cảm biến chuyển động',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB9E5FF),
                  Color(0xFFE5F6FF),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.sensors_rounded,
                  color: blue,
                  size: 68,
                ),
                SizedBox(height: 14),
                Text(
                  'Theo dõi chuyển động',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Xem dữ liệu gia tốc của thiết bị '
                      'khi em chủ động bật cảm biến.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Gia tốc theo 3 trục',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _axisCard('X', _x),
              const SizedBox(width: 10),
              _axisCard('Y', _y),
              const SizedBox(width: 10),
              _axisCard('Z', _z),
            ],
          ),

          const SizedBox(height: 16),

          _detailCard(
            icon: Icons.speed_outlined,
            title: 'Độ lớn gia tốc',
            value: _hasData
                ? '${_magnitude.toStringAsFixed(2)} m/s²'
                : 'Chưa có dữ liệu',
          ),

          const SizedBox(height: 12),

          _detailCard(
            icon: Icons.directions_run,
            title: 'Mức chuyển động',
            value: _motionStatus,
          ),

          const SizedBox(height: 12),

          _detailCard(
            icon: _isListening
                ? Icons.sensors
                : Icons.sensors_off,
            title: 'Trạng thái cảm biến',
            value: _isListening
                ? (_hasData
                ? 'Đang nhận dữ liệu'
                : 'Đang chờ dữ liệu')
                : 'Đã dừng',
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFB3261E),
                ),
              ),
            ),
          ],

          const SizedBox(height: 22),

          FilledButton.icon(
            onPressed: _isListening
                ? _stopListening
                : _startListening,
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: Icon(
              _isListening
                  ? Icons.stop_circle_outlined
                  : Icons.play_arrow_rounded,
            ),
            label: Text(
              _isListening
                  ? 'Dừng đọc cảm biến'
                  : 'Bắt đầu đọc cảm biến',
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Dữ liệu chỉ hiển thị trên thiết bị này '
                'khi màn hình đang hoạt động. '
                'Không gửi dữ liệu chuyển động lên Backend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
