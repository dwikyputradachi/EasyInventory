import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

const String kOnboardingDoneKey = 'has_seen_onboarding';

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingData({required this.icon, required this.title, required this.description});
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingPage({super.key, required this.onFinished});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _slides = [
    _OnboardingData(
      icon: Icons.inventory_2_outlined,
      title: 'Easy Inventory',
      description: 'Kelola inventaris rumah tangga dengan lebih mudah dan terorganisir.',
    ),
    _OnboardingData(
      icon: Icons.document_scanner_outlined,
      title: 'Scan Struk Otomatis',
      description: 'Foto struk belanja dan biarkan sistem membaca daftar produk secara otomatis.',
    ),
    _OnboardingData(
      icon: Icons.fact_check_outlined,
      title: 'Pantau Inventaris',
      description: 'Lihat stok barang, tanggal kedaluwarsa, dan kategori produk dalam satu aplikasi.',
    ),
    _OnboardingData(
      icon: Icons.bar_chart_rounded,
      title: 'Analisis Pengeluaran',
      description: 'Pantau pengeluaran bulanan dan dapatkan rekomendasi budget berdasarkan kebiasaan belanja.',
    ),
  ];

  bool get _isLastPage => _index == _slides.length - 1;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingDoneKey, true);
    if (mounted) widget.onFinished();
  }

  void _next() {
    if (_isLastPage) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: _isLastPage
                    ? const SizedBox(height: 40)
                    : TextButton(
                        onPressed: _finish,
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(data: _slides[i]),
              ),
            ),
            _Indicator(count: _slides.length, index: _index),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _isLastPage ? 'Get Started' : 'Next',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _OnboardingData data;
  const _SlideView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 76, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final int count;
  final int index;
  const _Indicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}