import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/auth_service.dart';
import 'package:quickalert/quickalert.dart';
class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState
    extends State<ResetPasswordPage> {
  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmController =
      TextEditingController();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }



Future<void> _resetPassword() async {
  final password = _passwordController.text.trim();
  final confirm = _confirmController.text.trim();

  if (password.isEmpty || confirm.isEmpty) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: "Error",
      text: "Semua field wajib diisi",
    );
    return;
  }

  if (password.length < 6) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: "Error",
      text: "Password minimal 6 karakter",
    );
    return;
  }

  if (password != confirm) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: "Error",
      text: "Konfirmasi password tidak sama",
    );
    return;
  }

  QuickAlert.show(
    context: context,
    type: QuickAlertType.confirm,
    title: "Reset Password",
    text: "Are you sure you want to reset your password?",
    confirmBtnText: "Yes",
    cancelBtnText: "No",
    onConfirmBtnTap: () async {
      Navigator.pop(context);

      setState(() => _isLoading = true);

      final result = await AuthService.resetPassword(
        email: widget.email,
        password: password,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result["success"] == true) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: "Success",
          text: result["message"] ?? "Password berhasil diubah",
          onConfirmBtnTap: () {
            Navigator.pop(context);

            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
          },
        );
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: "Failed",
          text: result["message"] ?? "Gagal mengubah password",
        );
      }
    },
  );
}

  InputDecoration _input(
    String hint,
    IconData icon,
    bool show,
    VoidCallback onTap,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          show
              ? Icons.visibility
              : Icons.visibility_off,
        ),
        onPressed: onTap,
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
        title: const Text("Reset Password"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 25),

            Text(
              widget.email,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller:
                  _passwordController,
              obscureText: !_showPassword,
              decoration: _input(
                "Password Baru",
                Icons.lock_outline,
                _showPassword,
                () {
                  setState(() {
                    _showPassword =
                        !_showPassword;
                  });
                },
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller:
                  _confirmController,
              obscureText: !_showConfirm,
              decoration: _input(
                "Konfirmasi Password",
                Icons.lock_outline,
                _showConfirm,
                () {
                  setState(() {
                    _showConfirm =
                        !_showConfirm;
                  });
                },
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading
                    ? null
                    : _resetPassword,
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Reset Password",
                        style:
                            TextStyle(
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