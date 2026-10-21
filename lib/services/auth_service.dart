
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {

  // 1. ĐĂNG KÝ TÀI KHOẢN
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}Auth/register',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': 'Parent',
      }),
    );

    return _handleResponse(response, 'Đăng ký');
  }

  // 2. ĐĂNG NHẬP
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}Auth/login',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    return _handleResponse(response, 'Đăng nhập');
  }

  // 3. XÁC THỰC OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}Auth/verify-otp',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'otpCode': otpCode.trim(),
      }),
    );

    return _handleResponse(response, 'Xác thực OTP');
  }

  // 4. XỬ LÝ PHẢN HỒI TỪ BACKEND
  Map<String, dynamic> _handleResponse(
      http.Response response,
      String action,
      ) {
    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else {
          data = {'data': decoded};
        }
      } catch (_) {
        throw Exception(
          '$action: Backend trả về dữ liệu không hợp lệ',
        );
      }
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    final errors = data['errors'];
    String? validationMessage;

    if (errors is Map) {
      validationMessage = errors.values
          .whereType<List>()
          .expand((items) => items)
          .map((item) => item.toString())
          .join('\n');
    }

    final message = (validationMessage != null &&
        validationMessage.isNotEmpty)
        ? validationMessage
        : (data['message'] ??
        data['title'] ??
        '$action thất bại (HTTP ${response.statusCode})')
        .toString();

    throw Exception(message);
  }
}
