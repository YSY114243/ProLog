import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/app_spacing.dart';

class FeaturesSection extends StatelessWidget {
  final bool isMobile;

  const FeaturesSection({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        icon: Icons.camera_alt_outlined,
        title: 'Seamless Capture',
        description: 'Document site activities in seconds. Keep every detail organized automatically without manual data entry.',
      ),
      _FeatureData(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Instant Reporting',
        description: 'Generate pristine, university-ready PDFs. Formatted perfectly with zero layout struggles.',
      ),
      _FeatureData(
        icon: Icons.cloud_sync_outlined,
        title: 'Cloud Resilience',
        description: 'Your data is protected. Sync observations securely across all devices instantly.',
      ),
      _FeatureData(
        icon: Icons.bolt_outlined,
        title: 'Auto-Optimization',
        description: 'Upload massive site photos without hitting storage limits. Intelligently optimized for clarity.',
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: EdgeInsets.symmetric(vertical: isMobile ? AppSpacing.sectionMobile : AppSpacing.sectionDesktop),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 64.0),
            child: Column(
              children: [
                const Text('FEATURES', style: AppTextStyles.sectionEyebrow),
                const SizedBox(height: AppSpacing.md),
                const Text('Engineered for the field.', textAlign: TextAlign.center, style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'A precision toolkit that gets out of your way so you can focus on the site.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 100),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1024) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: features.asMap().entries.map((entry) {
                            final isLast = entry.key == features.length - 1;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: isLast ? 0 : 32.0),
                                child: _HoverableFeatureCard(data: entry.value),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    } else if (constraints.maxWidth >= 800) {
                      return Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _HoverableFeatureCard(data: features[0])),
                                const SizedBox(width: 32),
                                Expanded(child: _HoverableFeatureCard(data: features[1])),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _HoverableFeatureCard(data: features[2])),
                                const SizedBox(width: 32),
                                Expanded(child: _HoverableFeatureCard(data: features[3])),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: features.asMap().entries.map((entry) {
                          final isLast = entry.key == features.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
                            child: _HoverableFeatureCard(data: entry.value),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureData {
  final dynamic icon;
  final String title;
  final String description;

  _FeatureData({required this.icon, required this.title, required this.description});
}

class _HoverableFeatureCard extends StatefulWidget {
  final _FeatureData data;

  const _HoverableFeatureCard({required this.data});

  @override
  State<_HoverableFeatureCard> createState() => _HoverableFeatureCardState();
}

class _HoverableFeatureCardState extends State<_HoverableFeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? AppColors.borderSubtle.withValues(alpha: 0.8) : AppColors.borderSubtle.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: _isHovered 
            ? AppColors.floatingShadow 
            : [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isHovered ? AppColors.accentRoyalBlue.withValues(alpha: 0.05) : AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isHovered ? AppColors.accentRoyalBlue.withValues(alpha: 0.2) : AppColors.borderSubtle.withValues(alpha: 0.5)),
              ),
              child: Icon(
                widget.data.icon, 
                size: 28, 
                color: _isHovered ? AppColors.accentRoyalBlue : AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.data.title, 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.data.description, 
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
