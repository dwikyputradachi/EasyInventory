import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/auth_service.dart';
import 'reset_password_page.dart';
import 'login_page.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String purpose;

  const OTPVerificationPage({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  State<OTPVerificationPage> createState() =>
      _OTPVerificationPageState();
}

class _OTPVerificationPageState
    extends State<OTPVerificationPage> {
  final TextEditingController _otpController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? Colors.red : AppColors.primary,
      ),
    );
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showMessage(
        "Masukkan kode OTP",
        error: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.verifyOTP(
      email: widget.email,
      otp: otp,
      purpose: widget.purpose,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result["success"] == true ||
        result["status"] == "success") {

      if (widget.purpose == "register") {

       ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Akun berhasil didaftarkan. Silakan login."),
    duration: Duration(seconds: 2),
  ),
);

Future.delayed(
  const Duration(seconds: 2),
  () {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  },
);

      } else {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(
              email: widget.email,
            ),
          ),
        );

      }

    } else {

      _showMessage(
        result["message"] ?? "OTP salah",
        error: true,
      );

    }
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final title = widget.purpose == "register"
        ? "Email Verification"
        : "OTP Verification";

    final subtitle = widget.purpose == "register"
        ? "Masukkan kode verifikasi yang telah dikirim ke"
        : "Masukkan kode OTP yang telah dikirim ke";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 25),

            Text(
              "$subtitle\n\n${widget.email}",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: _inputDecoration(
                "Masukkan OTP",
                Icons.password,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading
                    ? null
                    : _verifyOTP,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Verify OTP",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}