import 'package:flutter/material.dart';
import '../../widgets/intern_log_logo.dart';
import '../../core/app_colors.dart';
import '../../core/app_spacing.dart';
import '../../screens/auth_screen.dart';

class Footer extends StatelessWidget {
  final bool isMobile;

  const Footer({super.key, required this.isMobile});

  void _navigateToAuth(BuildContext context, {required bool isSignUp}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen(initialIsSignUp: isSignUp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 64.0),
            child: isMobile
                ? Column(
                    children: [
                      const InternLogLogo.medium(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildLinks(context),
                      const SizedBox(height: AppSpacing.xxl),
                      const Text(
                        '© 2026 InternLog. All rights reserved.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InternLogLogo.medium(),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            '© 2026 InternLog. All rights reserved.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      _buildLinks(context),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinks(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _navigateToAuth(context, isSignUp: false),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Log in'),
        ),
        const SizedBox(width: AppSpacing.lg),
        TextButton(
          onPressed: () => _navigateToAuth(context, isSignUp: true),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Sign up'),
        ),
      ],
    );
  }
}
