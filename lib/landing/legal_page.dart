import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'widgets/navbar.dart';
import 'widgets/footer.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final String content;

  const LegalPage({super.key, required this.title, required this.content});

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
                      Container(
                        width: double.infinity,
                        color: AppColors.surfaceWhite,
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 24.0 : 64.0, vertical: 60.0),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  content,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.8,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
