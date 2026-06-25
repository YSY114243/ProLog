// Removed foundation import
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  final TextEditingController _licenseController = TextEditingController();

  final String gumroadProductLink = 'https://yahyay.gumroad.com/l/internlog';
  final String gumroadPermalink = 'internlog';

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _launchGumroad() async {
    final Uri url = Uri.parse(gumroadProductLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $gumroadProductLink')),
        );
      }
    }
  }

  Future<void> _verifyLicenseKey() async {
    final key = _licenseController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an activation key.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await http.post(
        Uri.parse('https://api.gumroad.com/v2/licenses/verify'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'product_permalink': 'internlog',
          'license_key': key,
        },
      );

      print('Gumroad Response: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _onPaymentSuccess();
        return;
      }
      
      // If we reach here, it failed
      if (mounted) {
        final errorMessage = data['message'] ?? 'Invalid or expired activation key.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network/Connection Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _onPaymentSuccess() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
            
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'is_premium': true},
        ),
      );

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Welcome to Premium!'),
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
    }
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: Theme.of(context).colorScheme.onSurface,
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      (r) => false,
                    );
                  }
                },
              ),
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
                      '\$9.99',
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
                      'One-time payment (~38 SAR)',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isProcessing)
                    Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                  else
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _launchGumroad,
                          icon: Icon(Icons.shopping_cart_rounded, color: Theme.of(context).colorScheme.surface),
                          label: const Text(
                            'Buy Premium via Gumroad',
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
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _licenseController,
                          decoration: InputDecoration(
                            labelText: 'Enter Activation Key',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.key_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _verifyLicenseKey,
                          icon: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary),
                          label: Text(
                            'Activate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ),
                      ],
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