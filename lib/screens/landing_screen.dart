import 'package:flutter/material.dart';
import 'auth_screen.dart';

// Brand Colors aligned with Core Theme

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Sticky Header
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            centerTitle: false,
            title: Padding(
              padding: EdgeInsets.only(left: isMobile ? 8.0 : 40.0),
              child: Row(
                children: [
                  Icon(Icons.business_center_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'InternLog',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
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
                        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                        textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      child: Text('Login'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _navigateToAuth(context, isSignUp: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.surface,
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                _buildCopy(context, textAlign: TextAlign.center),
                SizedBox(height: 48),
                _buildMockup(context),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 5, child: _buildCopy(context, textAlign: TextAlign.left)),
                SizedBox(width: 60),
                Expanded(flex: 5, child: _buildMockup(context)),
              ],
            ),
    );
  }

  Widget _buildCopy(BuildContext context, {required TextAlign textAlign}) {
    final alignment = textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🚀 Built for Engineering Students',
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Master Your Summer Training Logs with InternLog.',
          textAlign: textAlign,
          style: TextStyle(
            fontSize: isMobile ? 40 : 56,
            fontWeight: FontWeight.w900,
            height: 1.1,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -1.0,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'The ultimate digital daily log tool built for engineering students. Document site work, attach photos, and generate university-ready PDF reports instantly.',
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 18,
            height: 1.5,
            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          ),
        ),
        SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: textAlign == TextAlign.center ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: onStartTrial,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.surface,
                elevation: 4,
                shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Start 3-Day Free Trial',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton(
              onPressed: onLearnMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildMockup(BuildContext context) {
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
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: Icon(Icons.dashboard_customize_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
            ),
            SizedBox(height: 24),
            Text(
              'Modern Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
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
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 80.0,
      ),
      child: Column(
        children: [
          Text(
            'Everything You Need',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Powerful features designed specifically for civil engineering students.',
            style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          if (isMobile)
            Column(
              children: features.map((f) => Padding(padding: EdgeInsets.only(bottom: 24), child: _buildFeatureCard(context, f))).toList(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildFeatureCard(context, features[0]),
                      SizedBox(height: 24),
                      _buildFeatureCard(context, features[1]),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildFeatureCard(context, features[2]),
                      SizedBox(height: 24),
                      _buildFeatureCard(context, features[3]),
                    ],
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureData feature) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: Theme.of(context).colorScheme.primary, size: 28),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ),
                SizedBox(height: 8),
                Text(
                  feature.description,
                  style: TextStyle(fontSize: 15, height: 1.5, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
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
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 80.0,
      ),
      child: Column(
        children: [
          Text(
            'How It Works',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          isMobile
              ? Column(
                  children: [
                    _buildStep(context, 1, Icons.camera_alt_rounded, 'Snap & Upload', 'Take a photo of the site or materials.'),
                    SizedBox(height: 32),
                    _buildStep(context, 2, Icons.edit_document, 'Add Details', 'Write your engineering observations.'),
                    SizedBox(height: 32),
                    _buildStep(context, 3, Icons.send_rounded, 'Export & Submit', 'Download the ready PDF and submit it to your supervisor.'),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStep(context, 1, Icons.camera_alt_rounded, 'Snap & Upload', 'Take a photo of the site or materials.')),
                    SizedBox(width: 40),
                    Expanded(child: _buildStep(context, 2, Icons.edit_document, 'Add Details', 'Write your engineering observations.')),
                    SizedBox(width: 40),
                    Expanded(child: _buildStep(context, 3, Icons.send_rounded, 'Export & Submit', 'Download the ready PDF and submit it to your supervisor.')),
                  ],
                )
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int number, IconData icon, String title, String description) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Step $number',
            style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(fontSize: 16, height: 1.5, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
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
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 80.0,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 800),
          padding: EdgeInsets.all(isMobile ? 32 : 48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Transparent & Simple Pricing',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.surface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Text(
                r'Start for free, unlock unlimited professional features for just $5.' '\n(One-time fee for the entire summer)',
                style: TextStyle(fontSize: 18, height: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: onGetPremium,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.primary,
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
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 40.0,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLogo(context),
                SizedBox(height: 16),
                _buildCopyright(context),
                SizedBox(height: 16),
                _buildLinks(context),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(context),
                    SizedBox(height: 8),
                    _buildCopyright(context),
                  ],
                ),
                _buildLinks(context),
              ],
            ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.business_center_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
        SizedBox(width: 8),
        Text(
          'InternLog',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyright(BuildContext context) {
    return Text(
      '© 2026 InternLog. All rights reserved.',
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, fontSize: 14),
    );
  }

  Widget _buildLinks(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
          child: Text('Login', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        SizedBox(width: 16),
        TextButton(
          onPressed: onSignUp,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
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
