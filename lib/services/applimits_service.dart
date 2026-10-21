
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_service.dart';

class AppLimitsService {
  Future<Map<String, String>> _headers() async {
    final token = await TokenService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Phiên đăng nhập đã hết. Hãy đăng nhập lại.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) {
    return Uri.parse('${ApiConfig.baseUrl}AppLimits$path');
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập không hợp lệ');
    }

    if (response.statusCode == 403) {
      throw Exception('Bạn không có quyền thực hiện thao tác này');
    }

    String message = 'HTTP ${response.statusCode}';

    try {
      final data = jsonDecode(response.body);

      if (data is Map) {
        message = data['message']?.toString() ??
            data['title']?.toString() ??
            message;
      }
    } catch (_) {}

    throw Exception(message);
  }

  // READ - DANH SÁCH GIỚI HẠN
  Future<List<Map<String, dynamic>>> getLimits(
      int deviceId,
      ) async {
    final response = await http.get(
      _url('/$deviceId'),
      headers: await _headers(),
    );

    _checkResponse(response);

    if (response.statusCode == 204 ||
        response.body.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('API không trả về danh sách hợp lệ');
    }

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // CREATE - THÊM GIỚI HẠN
  Future<void> createLimit({
    required int deviceId,
    required String appName,
    required String packageName,
    required int allowedMinutesPerDay,
    required bool isBlocked,
  }) async {
    final response = await http.post(
      _url(''),
      headers: await _headers(),
      body: jsonEncode({
        'deviceId': deviceId,
        'appName': appName.trim(),
        'packageName': packageName.trim(),
        'allowedMinutesPerDay': allowedMinutesPerDay,
        'isBlocked': isBlocked,
      }),
    );

    _checkResponse(response);
  }

  // UPDATE - CẬP NHẬT GIỚI HẠN
  Future<void> updateLimit({
    required int limitId,
    required int allowedMinutesPerDay,
    required bool isBlocked,
  }) async {
    final response = await http.put(
      _url('/$limitId'),
      headers: await _headers(),
      body: jsonEncode({
        'allowedMinutesPerDay': allowedMinutesPerDay,
        'isBlocked': isBlocked,
      }),
    );

    _checkResponse(response);
  }

  // DELETE - XÓA GIỚI HẠN
  Future<void> deleteLimit(int limitId) async {
    final response = await http.delete(
      _url('/$limitId'),
      headers: await _headers(),
    );

    _checkResponse(response);
  }
}
