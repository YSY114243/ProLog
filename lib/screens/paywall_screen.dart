import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import '../utils/paypal_facade.dart';
import '../utils/paddle_facade.dart';
import 'dashboard_screen.dart';
import '../landing/landing_page.dart';

class PaywallScreen extends StatefulWidget {
  final bool isVoluntary;

  const PaywallScreen({super.key, this.isVoluntary = false});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      initPaddle('YOUR_CLIENT_SIDE_TOKEN');
    }
  }

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
        SnackBar(
          content: Text('Welcome to InternLog Premium!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
      MaterialPageRoute(builder: (context) => const LandingPage()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.isVoluntary
          ? AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
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
                  Center(
                    child: Icon(Icons.workspace_premium_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 24),
                  
                  // Headline
                  Text(
                    widget.isVoluntary 
                        ? 'Upgrade to InternLog Premium' 
                        : 'Your 3-Day Free Trial\nHas Expired',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    'Upgrade to InternLog Premium to continue using the app and unlock exclusive features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // Benefits Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREMIUM BENEFITS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
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
                  Center(
                    child: Text(
                      '\$5.00',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'One-time payment (~20 SAR)',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isProcessing)
                    Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                  else if (kIsWeb)
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            openPaddleCheckout(
                              priceId: 'YOUR_PADDLE_PRICE_ID',
                              onSuccess: (data) => _onPaymentSuccess(),
                              onClosed: (data) => print('Paddle closed'),
                            );
                          },
                          icon: Icon(Icons.credit_card_rounded, color: Theme.of(context).colorScheme.surface),
                          label: const Text(
                            'Pay with Credit Card / Apple Pay',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.surface,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: buildPayPalButton(
                            amount: '5.00',
                            onSuccess: (details) => _onPaymentSuccess(),
                            onError: (err) => _onPaymentError(err),
                            onCancel: (data) => _onPaymentCancel(),
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _upgradeToPremium,
                      icon: Icon(Icons.payment_rounded, color: Theme.of(context).colorScheme.surface),
                      label: const Text(
                        'Unlock Premium via PayPal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  if (!widget.isVoluntary)
                    TextButton(
                      onPressed: _logout,
                      child: Text('Log out', style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey)),
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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}