import 'package:flutter/material.dart';
import 'auth_screen.dart';

// Modern SaaS Colors
const Color _kPrimaryIndigo = Color(0xFF4F46E5);
const Color _kSecondaryIndigo = Color(0xFF4338CA);
const Color _kLightBackground = Color(0xFFF9FAFB);
const Color _kDarkText = Color(0xFF111827);
const Color _kMutedText = Color(0xFF6B7280);

/// The newly redesigned Modern SaaS landing page for InternLog.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();

  void _scrollToFeatures() {
    final context = _featuresKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToAuth(BuildContext context, {required bool isSignUp}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(initialIsSignUp: isSignUp),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: _kLightBackground,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Sticky Header
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            centerTitle: false,
            title: Padding(
              padding: EdgeInsets.only(left: isMobile ? 8.0 : 40.0),
              child: Row(
                children: [
                  const Icon(Icons.business_center_rounded, color: _kPrimaryIndigo, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'InternLog',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _kDarkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: isMobile ? 8.0 : 40.0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => _navigateToAuth(context, isSignUp: false),
                      style: TextButton.styleFrom(
                        foregroundColor: _kMutedText,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      child: const Text('Login'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _navigateToAuth(context, isSignUp: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryIndigo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // 2. Hero Section
              _HeroSection(isMobile: isMobile, onLearnMore: _scrollToFeatures, onStartTrial: () => _navigateToAuth(context, isSignUp: true)),

              // 3. Features Section
              Container(key: _featuresKey, child: _FeaturesSection(isMobile: isMobile)),

              // 4. How It Works Section
              _HowItWorksSection(isMobile: isMobile),

              // 5. Pricing Section
              _PricingSection(isMobile: isMobile, onGetPremium: () => _navigateToAuth(context, isSignUp: true)),

              // 6. Footer
              _FooterBar(isMobile: isMobile, onLogin: () => _navigateToAuth(context, isSignUp: false), onSignUp: () => _navigateToAuth(context, isSignUp: true)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Sections ─────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onLearnMore;
  final VoidCallback onStartTrial;

  const _HeroSection({required this.isMobile, required this.onLearnMore, required this.onStartTrial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: isMobile ? 60.0 : 100.0,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildCopy(textAlign: TextAlign.center),
                const SizedBox(height: 48),
                _buildMockup(),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 5, child: _buildCopy(textAlign: TextAlign.left)),
                const SizedBox(width: 60),
                Expanded(flex: 5, child: _buildMockup()),
              ],
            ),
    );
  }

  Widget _buildCopy({required TextAlign textAlign}) {
    final alignment = textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _kPrimaryIndigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🚀 Built for Engineering Students',
            style: TextStyle(color: _kPrimaryIndigo, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Master Your Summer Training Logs with InternLog.',
          textAlign: textAlign,
          style: TextStyle(
            fontSize: isMobile ? 40 : 56,
            fontWeight: FontWeight.w900,
            height: 1.1,
            color: _kDarkText,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'The ultimate digital daily log tool built for engineering students. Document site work, attach photos, and generate university-ready PDF reports instantly.',
          textAlign: textAlign,
          style: const TextStyle(
            fontSize: 18,
            height: 1.5,
            color: _kMutedText,
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: textAlign == TextAlign.center ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: onStartTrial,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryIndigo,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: _kPrimaryIndigo.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Start 3-Day Free Trial',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton(
              onPressed: onLearnMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kDarkText,
                side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Learn More',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMockup() {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.dashboard_customize_rounded, size: 64, color: _kPrimaryIndigo),
            ),
            const SizedBox(height: 24),
            const Text(
              'Modern Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kSecondaryIndigo),
            )
          ],
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  final bool isMobile;

  const _FeaturesSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        icon: Icons.compress_rounded,
        title: 'Smart Image Compression',
        description: 'Save site photos directly without hitting storage limits. Automatically optimized for clarity and size.',
      ),
      _FeatureData(
        icon: Icons.picture_as_pdf_rounded,
        title: 'Instant PDF Export',
        description: 'Generate professional daily and weekly reports with automatic layout and custom watermarks.',
      ),
      _FeatureData(
        icon: Icons.cloud_sync_rounded,
        title: 'Cloud Sync',
        description: 'Never lose a log. Access your data securely from any device, anywhere, anytime.',
      ),
      _FeatureData(
        icon: Icons.auto_awesome_rounded,
        title: 'Auto-Formatting',
        description: 'Stop wrestling with Word docs. Focus on the engineering site, we handle the paperwork.',
      ),
    ];

    return Container(
      color: _kLightBackground,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 80.0,
      ),
      child: Column(
        children: [
          const Text(
            'Everything You Need',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _kDarkText,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Powerful features designed specifically for civil engineering students.',
            style: TextStyle(fontSize: 18, color: _kMutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          if (isMobile)
            Column(
              children: features.map((f) => Padding(padding: const EdgeInsets.only(bottom: 24), child: _buildFeatureCard(f))).toList(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildFeatureCard(features[0]),
                      const SizedBox(height: 24),
                      _buildFeatureCard(features[1]),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildFeatureCard(features[2]),
                      const SizedBox(height: 24),
                      _buildFeatureCard(features[3]),
                    ],
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureData feature) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kPrimaryIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: _kPrimaryIndigo, size: 28),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kDarkText),
                ),
                const SizedBox(height: 8),
                Text(
                  feature.description,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: _kMutedText),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  final bool isMobile;

  const _HowItWorksSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 80.0,
      ),
      child: Column(
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _kDarkText,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          isMobile
              ? Column(
                  children: [
                    _buildStep(1, Icons.camera_alt_rounded, 'Snap & Upload', 'Take a photo of the site or materials.'),
                    const SizedBox(height: 32),
                    _buildStep(2, Icons.edit_document, 'Add Details', 'Write your engineering observations.'),
                    const SizedBox(height: 32),
                    _buildStep(3, Icons.send_rounded, 'Export & Submit', 'Download the ready PDF and submit it to your supervisor.'),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStep(1, Icons.camera_alt_rounded, 'Snap & Upload', 'Take a photo of the site or materials.')),
                    const SizedBox(width: 40),
                    Expanded(child: _buildStep(2, Icons.edit_document, 'Add Details', 'Write your engineering observations.')),
                    const SizedBox(width: 40),
                    Expanded(child: _buildStep(3, Icons.send_rounded, 'Export & Submit', 'Download the ready PDF and submit it to your supervisor.')),
                  ],
                )
        ],
      ),
    );
  }

  Widget _buildStep(int number, IconData icon, String title, String description) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kPrimaryIndigo.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Icon(icon, size: 36, color: _kPrimaryIndigo),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _kDarkText,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Step $number',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kDarkText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(fontSize: 16, height: 1.5, color: _kMutedText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PricingSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onGetPremium;

  const _PricingSection({required this.isMobile, required this.onGetPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kLightBackground,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 80.0,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: EdgeInsets.all(isMobile ? 32 : 48),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPrimaryIndigo, _kSecondaryIndigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPrimaryIndigo.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Transparent & Simple Pricing',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                r'Start for free, unlock unlimited professional features for just $5.' '\n(One-time fee for the entire summer)',
                style: TextStyle(fontSize: 18, height: 1.5, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: onGetPremium,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _kPrimaryIndigo,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Premium',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;

  const _FooterBar({required this.isMobile, required this.onLogin, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 40.0,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 24),
                _buildLinks(),
                const SizedBox(height: 24),
                _buildCopyright(),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 8),
                    _buildCopyright(),
                  ],
                ),
                _buildLinks(),
              ],
            ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.business_center_rounded, color: _kPrimaryIndigo, size: 24),
        SizedBox(width: 8),
        Text(
          'InternLog',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _kDarkText,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyright() {
    return const Text(
      '© 2026 InternLog. All rights reserved.',
      style: TextStyle(color: _kMutedText, fontSize: 14),
    );
  }

  Widget _buildLinks() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(foregroundColor: _kMutedText),
          child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: onSignUp,
          style: TextButton.styleFrom(foregroundColor: _kMutedText),
          child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;

  _FeatureData({required this.icon, required this.title, required this.description});
}
