
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  Future<String> testConnection() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}Auth/login',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );

      return 'HTTP ${response.statusCode}\n${response.body}';
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }
}
