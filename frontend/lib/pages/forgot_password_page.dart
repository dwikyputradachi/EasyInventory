import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/auth_service.dart';
import 'otp_verification_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {

  final TextEditingController _emailController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _sendOTP() async {

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        "Email wajib diisi",
        error: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.sendOTP(
      email: email,
      purpose: "forgot_password",
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result["success"] == true ||
        result["status"] == "success") {

      _showMessage(
        result["message"] ??
            "OTP berhasil dikirim",
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationPage(
            email: email,
            purpose: "forgot_password",
          ),
        ),
      );

    } else {

      _showMessage(
        result["message"] ??
            "Gagal mengirim OTP",
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Forgot Password",
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const Text(
              "Masukkan email akun Anda.\nKode OTP akan dikirim ke email tersebut.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            TextField(
              controller:
                  _emailController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration:
                  _inputDecoration(
                "Email",
                Icons.email_outlined,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _isLoading
                        ? null
                        : _sendOTP,
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Send OTP",
                        style: TextStyle(
                          color:
                              Colors.white,
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