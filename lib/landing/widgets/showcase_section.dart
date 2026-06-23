import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_spacing.dart';

class ShowcaseSection extends StatelessWidget {
  final bool isMobile;

  const ShowcaseSection({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceWhite,
      padding: EdgeInsets.symmetric(vertical: isMobile ? AppSpacing.sectionMobile : AppSpacing.sectionDesktop),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 64.0),
            child: Column(
              children: [
                // Section Header
                const Text('WORKFLOW', style: AppTextStyles.sectionEyebrow),
                const SizedBox(height: AppSpacing.md),
                const Text('Designed for the field.\nPerfected for the office.', textAlign: TextAlign.center, style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.xxxl),
                const SizedBox(height: AppSpacing.xl),

                // Feature 1: Text Left / Image Right
                isMobile
                    ? Column(
                        children: [
                          _buildText(
                            'Document site activities in seconds.',
                            'Keep every detail organized automatically. Snap high-resolution photos and log observations directly from the construction site. Data is instantly synced and secured.',
                          ),
                          const SizedBox(height: 60),
                          _buildImage('assets/images/add_log.png'),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 5, child: _buildText(
                            'Document site activities in seconds.',
                            'Keep every detail organized automatically. Snap high-resolution photos and log observations directly from the construction site. Data is instantly synced and secured.',
                          )),
                          const SizedBox(width: 140),
                          Expanded(flex: 7, child: _buildImage('assets/images/add_log.png')),
                        ],
                      ),

                SizedBox(height: isMobile ? 120 : 240),

                // Feature 2: Image Left / Text Right
                isMobile
                    ? Column(
                        children: [
                          _buildText(
                            'Deliver flawless reports without the struggle.',
                            'No more late nights fighting formatting in Word. Generate pristine, university-ready PDF reports with a single click. Everything is perfectly aligned to engineering standards.',
                          ),
                          const SizedBox(height: 60),
                          _buildImage('assets/images/report.png'),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 7, child: _buildImage('assets/images/report.png')),
                          const SizedBox(width: 140),
                          Expanded(flex: 5, child: _buildText(
                            'Deliver flawless reports without the struggle.',
                            'No more late nights fighting formatting in Word. Generate pristine, university-ready PDF reports with a single click. Everything is perfectly aligned to engineering standards.',
                          )),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(fontSize: 40, letterSpacing: -1.5, height: 1.1),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          description,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildImage(String assetPath) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 750, maxWidth: 850),
      child: Container(
        padding: const EdgeInsets.all(1), // Subtle sub-pixel border trick
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.borderSubtle.withValues(alpha: 0.8),
              AppColors.borderSubtle.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppColors.floatingShadow,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(31),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(31),
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
