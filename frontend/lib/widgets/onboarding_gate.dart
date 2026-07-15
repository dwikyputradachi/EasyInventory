import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/onboarding_page.dart';
import '../pages/splash_page.dart';

/// Widget ini menjadi tujuan route '/'.
/// - Jika onboarding belum pernah dilihat -> tampilkan OnboardingPage.
/// - Jika sudah -> langsung render SplashPage seperti alur normal
///   (logic auth/redirect di SplashPage tidak diubah sama sekali).
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(kOnboardingDoneKey) ?? false;
    if (mounted) setState(() => _seenOnboarding = seen);
  }

  @override
  Widget build(BuildContext context) {
    if (_seenOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_seenOnboarding == true) return const SplashPage();
    return OnboardingPage(onFinished: () => setState(() => _seenOnboarding = true));
  }
}