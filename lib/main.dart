import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/paywall_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

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

  runApp(ProLogApp(isSignedIn: isSignedIn, showPaywall: showPaywall));
}

class ProLogApp extends StatelessWidget {
  final bool isSignedIn;
  final bool showPaywall;
  const ProLogApp({super.key, required this.isSignedIn, required this.showPaywall});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProLog – Professional Log',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      // If user is already signed-in route straight to the dashboard or paywall,
      // otherwise show the landing / auth flow.
      home: isSignedIn 
          ? (showPaywall ? const PaywallScreen() : const DashboardScreen()) 
          : const LandingScreen(),
    );
  }
}
