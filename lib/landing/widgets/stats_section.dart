import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';

class StatsSection extends StatelessWidget {
  final bool isMobile;

  const StatsSection({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 64.0),
            child: Column(
              children: [
                const Text(
                  'TRUSTED BY ENGINEERING STUDENTS WORLDWIDE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                isMobile
                    ? Column(
                        children: [
                          _buildStat('50k+', 'Logs Created'),
                          const SizedBox(height: AppSpacing.xl),
                          _buildStat('10k+', 'PDFs Generated'),
                          const SizedBox(height: AppSpacing.xl),
                          _buildStat('4.9/5', 'App Store Rating'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('50k+', 'Logs Created'),
                          _buildStat('10k+', 'PDFs Generated'),
                          _buildStat('4.9/5', 'App Store Rating'),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDeepNavy,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
