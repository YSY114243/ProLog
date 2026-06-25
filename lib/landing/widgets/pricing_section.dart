import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../screens/auth_screen.dart';

class PricingSection extends StatelessWidget {
  final bool isMobile;

  const PricingSection({super.key, required this.isMobile});



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
                const Text(
                  'PRICING',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentRoyalBlue,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Simple, transparent pricing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Start for free. Upgrade once for the whole summer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 80),
                isMobile
                    ? Column(
                        children: [
                          _buildPricingCard(
                            context,
                            title: 'Free Trial',
                            price: '\$0',
                            subtitle: 'For 3 Days',
                            features: ['3 Daily Logs', 'Basic PDF Export', 'Standard Compression'],
                            isPopular: false,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _buildPricingCard(
                            context,
                            title: 'Premium',
                            price: '\$9.99',
                            subtitle: 'One-time fee',
                            features: ['Unlimited Logs', 'Pro PDF Reports', 'Max Compression', 'Cloud Sync', 'Priority Support'],
                            isPopular: true,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildPricingCard(
                              context,
                              title: 'Free Trial',
                              price: '\$0',
                              subtitle: 'For 3 Days',
                              features: ['3 Daily Logs', 'Basic PDF Export', 'Standard Compression'],
                              isPopular: false,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(
                            child: _buildPricingCard(
                              context,
                              title: 'Premium',
                              price: '\$9.99',
                              subtitle: 'One-time fee',
                              features: ['Unlimited Logs', 'Pro PDF Reports', 'Max Compression', 'Cloud Sync', 'Priority Support'],
                              isPopular: true,
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

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String subtitle,
    required List<String> features,
    required bool isPopular,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isPopular ? AppColors.primaryDeepNavy : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPopular ? AppColors.primaryDeepNavy : AppColors.borderSubtle, width: 2),
        boxShadow: isPopular ? AppColors.floatingShadow : AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.accentRoyalBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(color: AppColors.surfaceWhite, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isPopular ? AppColors.surfaceWhite : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: isPopular ? AppColors.surfaceWhite : AppColors.textPrimary,
                  letterSpacing: -2.0,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: isPopular ? AppColors.surfaceWhite.withValues(alpha: 0.7) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: isPopular ? AppColors.accentRoyalBlue : AppColors.borderSubtle,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 16,
                        color: isPopular ? AppColors.surfaceWhite : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuthScreen(
                      initialIsSignUp: true,
                      intentToPurchase: isPopular,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? AppColors.accentRoyalBlue : AppColors.background,
                foregroundColor: isPopular ? AppColors.surfaceWhite : AppColors.textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isPopular ? 'Get Premium' : 'Start Free Trial',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
