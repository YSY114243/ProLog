import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'widgets/navbar.dart';
import 'widgets/pricing_section.dart';
import 'widgets/footer.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              Navbar(isMobile: isMobile),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      PricingSection(isMobile: isMobile),
                      const SizedBox(height: 60),
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
