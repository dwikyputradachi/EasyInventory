import 'package:flutter/material.dart';
import '../constants/colors.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              "Create an account so you can start managing\nyour inventory easily",
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            TextField(
              decoration: InputDecoration(
                hintText: "Email",
                hintStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                hintStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Confirm Password",
                hintStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
              ),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Already have an account? Sign In",
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}