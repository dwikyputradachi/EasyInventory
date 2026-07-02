
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.primary,
      ),
    );
  }

  Future<void> _onLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Email dan password wajib diisi', error: true);
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthService.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _snack(res['message'] ?? 'Login gagal', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = _isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
   Image.asset(
  'assets/fonts/images/logo.png',
  width: 145,
  height: 145,
  fit: BoxFit.contain,
),
                const SizedBox(height: 18),
                const Text(
                  "Welcome to Easy Inventory",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Manage your household smarter",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _input(
                            "Email",
                            Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: !_showPassword,
                          decoration: _input(
                            "Password",
                            Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordPage(),
      ),
    );
  },
  child: const Text(
    "Forgot Password?",
    style: TextStyle(
      color: AppColors.primary,
      fontSize: 12,
    ),
  ),
),
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: disabled ? null : _onLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: disabled
                          ? null
                          : () => Navigator.pushNamed(
                                context,
                                '/register',
                              ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
        ),
      ),
    );
  }
}
