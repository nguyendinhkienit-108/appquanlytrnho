
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/token_service.dart';

import 'parent/parent_dashboard.dart';
import 'child/child_dashboard.dart';
import 'admin/admin_dashboard.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController =
  TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF168FE0);
  static const Color backgroundColor = Color(0xFFF2F9FF);


  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.redAccent : primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showMessage(
        'Vui lòng nhập mã OTP.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Gửi OTP lên Backend
      final result = await _authService.verifyOtp(
        email: widget.email,
        otpCode: otp,
      );

      // 2. Nhận dữ liệu trả về
      final success = result['success'] == true;

      final token = result['token']?.toString();

      final role =
      result['role']?.toString().trim().toLowerCase();

      final fullName =
          result['fullName']?.toString() ?? 'Người dùng';

      final userIdValue = result['userId'];

      final int? userId = userIdValue is int
          ? userIdValue
          : int.tryParse(
        userIdValue?.toString() ?? '',
      );

      // 3. Kiểm tra kết quả xác thực
      if (!success) {
        throw Exception(
          result['message']?.toString() ??
              'Mã OTP không chính xác.',
        );
      }

      if (token == null || token.isEmpty) {
        throw Exception(
          'Backend không trả về JWT.',
        );
      }

      if (role == null || role.isEmpty) {
        throw Exception(
          'Backend không trả về vai trò tài khoản.',
        );
      }

      // 4. Phân quyền điều hướng
      late final Widget destination;

      switch (role) {
        case 'parent':
          if (userId == null) {
            throw Exception(
              'Backend không trả về userId hợp lệ.',
            );
          }

          destination = ParentDashboard(
            parentId: userId,
            fullName: fullName,
          );
          break;

        case 'admin':
          destination = AdminDashboard(
            fullName: fullName,
          );
          break;

        case 'child':
          destination = ChildDashboard(
            fullName: fullName,
          );
          break;

        default:
          throw Exception(
            'Vai trò chưa được hỗ trợ: $role',
          );
      }

      // 5. Lưu JWT
      await TokenService.saveToken(token);

      if (!mounted) return;

      // 6. Chuyển đến Dashboard tương ứng
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => destination,
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Xác thực OTP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                // Header xanh biển nhạt
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB9E5FF),
                        Color(0xFFE7F7FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                    BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.75,
                          ),
                          borderRadius:
                          BorderRadius.circular(26),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: primaryBlue,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Xác thực tài khoản',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF19354D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Nhập mã xác thực được gửi '
                            'đến email của bạn',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF566D7D),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // Email
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFDCEFFD),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email nhận OTP',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Mã xác thực OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // Nhập OTP
                TextField(
                  controller: _otpController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [
                    AutofillHints.oneTimeCode,
                  ],
                  onSubmitted: (_) {
                    if (!_isLoading) {
                      _verifyOtp();
                    }
                  },
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã OTP',
                    hintStyle: const TextStyle(
                      fontSize: 16,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: const Icon(
                      Icons.password_rounded,
                      color: primaryBlue,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(
                      vertical: 19,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(17),
                      borderSide: const BorderSide(
                        color: Color(0xFFD3E8F6),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(17),
                      borderSide: const BorderSide(
                        color: primaryBlue,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF6C8CA5),
                      size: 17,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mã OTP dùng để xác nhận '
                            'đăng nhập an toàn.',
                        style: TextStyle(
                          color: Color(0xFF6C8CA5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Nút xác nhận
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed:
                    _isLoading ? null : _verifyOtp,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_outlined),
                        SizedBox(width: 10),
                        Text(
                          'Xác nhận OTP',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(
                    'Quay lại đăng nhập',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
