import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? AppColors.danger : AppColors.primary,
      ),
    );
  }

  Future<void> _onRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _snack(
        "Semua field wajib diisi",
        error: true,
      );
      return;
    }

    if (password != confirm) {
      _snack(
        "Password tidak cocok",
        error: true,
      );
      return;
    }

    if (password.length < 8) {
      _snack(
        "Password minimal 8 karakter",
        error: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await AuthService.register(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res["status"] == "success" ||
        res["success"] == true) {

      // KUNCI PERBAIKAN: Ambil nilai otp_testing dari dalam key "data" response API kamu
      String? testingOtp;
      if (res["data"] != null && res["data"]["otp_testing"] != null) {
        testingOtp = res["data"]["otp_testing"].toString();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationPage(
            email: email,
            purpose: "register",
            autoFillOtp: testingOtp, // <-- Sekarang nilai OTP dioper ke sini!
          ),
        ),
      );

    } else {

      _snack(
        res["message"] ?? "Registrasi gagal",
        error: true,
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [

                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      AppColors.primary.withOpacity(.12),
                  child: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Start managing your inventory easily",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(18),
                    child: Column(
                      children: [

                        TextField(
                          controller: _nameCtrl,
                          decoration: _input(
                            "Full Name",
                            Icons.person_outline,
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: _emailCtrl,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration: _input(
                            "Email",
                            Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller:
                              _passwordCtrl,
                          obscureText:
                              !_showPassword,
                          decoration: _input(
                            "Password",
                            Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword =
                                      !_showPassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller:
                              _confirmCtrl,
                          obscureText:
                              !_showConfirm,
                          decoration: _input(
                            "Confirm Password",
                            Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _showConfirm
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showConfirm =
                                      !_showConfirm;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _onRegister,
                            style:
                                FilledButton.styleFrom(
                              backgroundColor:
                                  AppColors.primary,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
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
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Text(
                                    "Sign Up",
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.white,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [

                    const Text(
                      "Already have an account?",
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),
      suffixIcon: suffix,
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
}