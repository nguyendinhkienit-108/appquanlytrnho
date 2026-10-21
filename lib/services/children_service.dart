
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class ChildrenService {
  Future<Map<String, String>> _headers() async {
    final token = await TokenService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Lấy danh sách trẻ em
  Future<dynamic> getMyKids(int parentId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}Children/my-kids/$parentId',
    );

    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Không tải được danh sách: HTTP ${response.statusCode}',
    );
  }

  // Thêm trẻ em
  Future<void> createChild({
    required int parentId,
    required String childName,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}Children/create',
    );

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'parentId': parentId,
        'childName': childName.trim(),
      }),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Thêm trẻ em thất bại: HTTP ${response.statusCode}\n'
            '${response.body}',
      );
    }
  }

  // XEM CHI TIẾT THIẾT BỊ
  Future<Map<String, dynamic>> getChildDetail(int deviceId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}Children/$deviceId',
    );

    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Dữ liệu thiết bị không đúng định dạng');
    }

    throw Exception(
      'Không lấy được chi tiết: HTTP ${response.statusCode}',
    );
  }

  // XÓA THIẾT BỊ
  Future<void> deleteChild(int deviceId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}Children/$deviceId',
    );

    final response = await http.delete(
      url,
      headers: await _headers(),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Xóa thiết bị thất bại: HTTP ${response.statusCode}',
      );
    }
  }

}
