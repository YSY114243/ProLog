import 'package:flutter/material.dart';
import '../../widgets/intern_log_logo.dart';
import '../../core/app_colors.dart';
import '../../screens/auth_screen.dart';

class Navbar extends StatelessWidget {
  final bool isMobile;

  const Navbar({super.key, required this.isMobile});

  void _navigateToAuth(BuildContext context, {required bool isSignUp}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen(initialIsSignUp: isSignUp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 64.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const InternLogLogo.medium(),
                if (!isMobile)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/pricing'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        child: const Text('Pricing'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => _navigateToAuth(context, isSignUp: false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        child: const Text('Log in'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _navigateToAuth(context, isSignUp: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: AppColors.surfaceWhite,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Start for free', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/pricing'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        child: const Text('Pricing'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                        onPressed: () => _navigateToAuth(context, isSignUp: true),
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
}
