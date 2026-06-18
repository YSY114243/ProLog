import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import '../theme/app_theme.dart';
import '../utils/paypal_facade.dart';
import 'dashboard_screen.dart';
import 'landing_screen.dart';

class PaywallScreen extends StatefulWidget {
  final bool isVoluntary;

  const PaywallScreen({super.key, this.isVoluntary = false});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isProcessing = false;

  Future<void> _onPaymentSuccess() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
            
    setState(() => _isProcessing = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'is_premium': true},
        ),
      );

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Welcome to InternLog Premium!'),
          backgroundColor: AppTheme.primaryCyan,
        ),
      );

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (r) => false,
      );
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to activate premium: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onPaymentError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Error: $error')),
    );
  }

  void _onPaymentCancel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Cancelled')),
    );
  }

  void _upgradeToPremium() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
          sandboxMode: false,
          clientId: "Ae7xARZuVt90cXuMSC7Bdri_bcoxPUSKJ6kIxz2mloWwMLFURhaFYi1zEg5dpp3zwo_x37h878AUKpqC",
          secretKey: "PLACEHOLDER_NOT_NEEDED_FOR_CLIENT_SDK_BUT_REQUIRED_BY_PLUGIN",
          returnURL: "https://samplesite.com/return",
          cancelURL: "https://samplesite.com/cancel",
          transactions: const [
            {
              "amount": {
                "total": '5.00',
                "currency": "USD",
                "details": {
                  "subtotal": '5.00',
                  "shipping": '0',
                  "shipping_discount": 0
                }
              },
              "description": "InternLog Premium Lifetime Subscription",
              "item_list": {
                "items": [
                  {
                    "name": "InternLog Premium",
                    "quantity": 1,
                    "price": '5.00',
                    "currency": "USD"
                  }
                ],
              }
            }
          ],
          note: "Contact support for any queries.",
          onSuccess: (Map params) async => _onPaymentSuccess(),
          onError: (error) => _onPaymentError(error),
          onCancel: (params) => _onPaymentCancel(),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: widget.isVoluntary
          ? AppBar(
              backgroundColor: AppTheme.scaffoldBg,
              elevation: 0,
              leading: const BackButton(color: AppTheme.textPrimary),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon/Illustration
                  const Center(
                    child: Icon(Icons.workspace_premium_rounded, size: 80, color: AppTheme.primaryCyan),
                  ),
                  const SizedBox(height: 24),
                  
                  // Headline
                  Text(
                    widget.isVoluntary 
                        ? 'Upgrade to InternLog Premium' 
                        : 'Your 3-Day Free Trial\nHas Expired',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  const Text(
                    'Upgrade to InternLog Premium to continue using the app and unlock exclusive features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 40),

                  // Benefits Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.textPrimary.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PREMIUM BENEFITS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildBenefitRow(Icons.photo_library_rounded, 'Unlimited Image Uploads'),
                        const SizedBox(height: 16),
                        _buildBenefitRow(Icons.picture_as_pdf_rounded, 'Custom University PDF Cover'),
                        const SizedBox(height: 16),
                        _buildBenefitRow(Icons.table_chart_rounded, 'Advanced Excel Exports'),
                        const SizedBox(height: 16),
                        _buildBenefitRow(Icons.all_inclusive_rounded, 'Lifetime Access (One-time fee)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Price & CTA
                  const Center(
                    child: Text(
                      '\$5.00',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'One-time payment (~20 SAR)',
                      style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator(color: AppTheme.primaryCyan))
                  else if (kIsWeb)
                    SizedBox(
                      height: 48,
                      child: buildPayPalButton(
                        amount: '5.00',
                        onSuccess: (details) => _onPaymentSuccess(),
                        onError: (err) => _onPaymentError(err),
                        onCancel: (data) => _onPaymentCancel(),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _upgradeToPremium,
                      icon: const Icon(Icons.payment_rounded, color: Colors.white),
                      label: const Text(
                        'Unlock Premium via PayPal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  if (!widget.isVoluntary)
                    TextButton(
                      onPressed: _logout,
                      child: const Text('Log out', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryCyan),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
