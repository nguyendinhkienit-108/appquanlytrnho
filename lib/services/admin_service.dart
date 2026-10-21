
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_service.dart';

class AdminService {
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final token = await TokenService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập hoặc thiếu JWT.');
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}Admin/dashboard-summary',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập đã hết hạn.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Tài khoản không có quyền truy cập Admin.',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Không tải được dữ liệu Admin '
            '(HTTP ${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Dữ liệu Admin không hợp lệ.');
    }

    return data;
  }
}
