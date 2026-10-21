
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_service.dart';

class TrackingService {
  Future<Map<String, String>> _headers() async {
    final token = await TokenService.getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Future<void> updateLocation({
    required int deviceId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await TokenService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Bạn cần đăng nhập trước khi gửi vị trí.',
      );
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}Tracking/update-location',
      ),
      headers: await _headers(),
      body: jsonEncode({
        'deviceId': deviceId,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    _checkResponse(response);
  }

  Future<Map<String, dynamic>> getLatestLocation(
      int deviceId,
      ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}Tracking/latest/$deviceId',
      ),
      headers: await _headers(),
    );

    _checkResponse(response);

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Dữ liệu vị trí từ Backend không hợp lệ.',
      );
    }

    return decoded;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Phiên đăng nhập đã hết hạn.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Bạn không có quyền truy cập vị trí này.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Chưa tìm thấy vị trí được chia sẻ.',
      );
    }

    throw Exception(
      'Lỗi API (${response.statusCode}): '
          '${response.body}',
    );
  }
}
