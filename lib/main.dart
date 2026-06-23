import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'landing/landing_page.dart';
import 'screens/paywall_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'landing/pricing_page.dart';
import 'landing/legal_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase before the widget tree is built.
  await SupabaseService.initialize();

  // Restore persisted session (Supabase does this synchronously after init).
  final user = Supabase.instance.client.auth.currentUser;
  final isSignedIn = user != null;
  bool showPaywall = false;

  if (user != null) {
    final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    final isPremium = user.userMetadata?['is_premium'] == true;
    if (daysSinceCreation > 3 && !isPremium) {
      showPaywall = true;
    }
  }

  runApp(InternLogApp(isSignedIn: isSignedIn, showPaywall: showPaywall));
}

class InternLogApp extends StatelessWidget {
  final bool isSignedIn;
  final bool showPaywall;
  const InternLogApp({super.key, required this.isSignedIn, required this.showPaywall});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InternLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => isSignedIn 
            ? (showPaywall ? const PaywallScreen() : const DashboardScreen()) 
            : const LandingPage(),
        '/pricing': (context) => const PricingPage(),
        '/terms': (context) => const LegalPage(
          title: 'Terms of Service',
          content: 'Welcome to InternLog. By using our service, you agree to these terms...\n\n1. Acceptance of Terms\nBy accessing and using InternLog, you accept and agree to be bound by the terms and provision of this agreement.\n\n2. Service Usage\nInternLog provides tools for students to document their internships. You agree to use these tools responsibly.\n\n3. Account Security\nYou are responsible for maintaining the confidentiality of your account credentials.\n\n4. Modifications\nWe reserve the right to modify these terms at any time.',
        ),
        '/privacy': (context) => const LegalPage(
          title: 'Privacy Policy',
          content: 'Your privacy is important to us.\n\n1. Information Collection\nWe collect information you provide directly to us when you create an account, such as your name and email.\n\n2. Use of Information\nWe use the information we collect to provide, maintain, and improve our services.\n\n3. Data Storage\nYour data is securely stored and is never sold to third parties.\n\n4. Contact Us\nIf you have any questions about this Privacy Policy, please contact us.',
        ),
        '/refund': (context) => const LegalPage(
          title: 'Refund Policy',
          content: 'Our Refund Policy for Premium Subscriptions.\n\n1. Free Trial\nWe offer a 3-day free trial so you can test all features before purchasing.\n\n2. Refunds\nSince we offer a free trial, all sales are considered final after the trial period ends. We do not offer refunds for the one-time premium purchase unless there is a technical failure on our end that prevents you from accessing the service.\n\n3. Exceptions\nIf you experience a billing error, please contact support within 7 days for a full refund.',
        ),
      },
    );
  }
}
