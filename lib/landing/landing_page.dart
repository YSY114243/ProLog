import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'widgets/navbar.dart';
import 'widgets/hero_section.dart';
import 'widgets/features_section.dart';
import 'widgets/showcase_section.dart';
import 'widgets/pricing_section.dart';
import 'widgets/footer.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Sticky Navbar
              Navbar(isMobile: isMobile),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      HeroSection(isMobile: isMobile),
                      FeaturesSection(isMobile: isMobile),
                      ShowcaseSection(isMobile: isMobile),
                      PricingSection(isMobile: isMobile),
                      Footer(isMobile: isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
