import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_spacing.dart';
import '../../screens/auth_screen.dart';

class HeroSection extends StatelessWidget {
  final bool isMobile;

  const HeroSection({super.key, required this.isMobile});

  void _navigateToAuth(BuildContext context, {required bool isSignUp}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen(initialIsSignUp: isSignUp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Subtle premium background glow
        Positioned(
          top: -200,
          left: 0,
          right: 0,
          child: Container(
            height: 600,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.5,
                colors: [
                  AppColors.accentRoyalBlue.withValues(alpha: 0.15),
                  AppColors.background.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: isMobile ? 80 : 160, bottom: isMobile ? 80 : 160),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 64.0),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildCopy(context),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: _buildCopy(context)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppColors.softShadow,
          ),
          child: const Text('InternLog 2.0 is live', style: AppTextStyles.sectionEyebrow),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Track your internship.\nGenerate reports automatically.',
          textAlign: TextAlign.center,
          style: isMobile ? AppTextStyles.h1.copyWith(fontSize: 44) : AppTextStyles.h1.copyWith(fontSize: 56, height: 1.1),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'The digital standard for engineering students. Turn daily site observations into university-ready reports instantly.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _navigateToAuth(context, isSignUp: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.surfaceWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start for free', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => _navigateToAuth(context, isSignUp: false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Log in to account →', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}
