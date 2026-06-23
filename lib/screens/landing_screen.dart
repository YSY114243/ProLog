import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/intern_log_logo.dart';
import 'auth_screen.dart';

// ── Brand Tokens ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF1E3A8A); // Primary Deep Navy
const _kBlue = Color(0xFF2563EB); // Vibrant Royal Blue (Buttons/Accents)
const _kSlate = Color(0xFFF8FAFC); // Background Light Slate
const _kInk = Color(0xFF0F172A); // Dark Slate Text
const _kSubtext = Color(0xFF64748B); // Secondary text
const _kBorder = Color(0xFFE2E8F0); // Dividers / card borders
const _kSurface = Color(0xFFFFFFFF); // Card / header surface

// ── Hero image constraints ────────────────────────────────────────────────────
const _kHeroImageMaxHeight = 480.0;
const _kFeatureImageMaxHeight = 380.0;

/// Premium redesigned landing page for InternLog.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();

  void _scrollToFeatures() {
    final ctx = _featuresKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    }
  }

  void _navigateToAuth(BuildContext context, {required bool isSignUp}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => AuthScreen(initialIsSignUp: isSignUp)),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 800;

    return Scaffold(
      backgroundColor: _kSlate,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Sticky Header ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: _kSurface,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _kBorder),
            ),
            title: Padding(
              padding: EdgeInsets.only(left: isMobile ? 4.0 : 32.0),
              child: const InternLogLogo.medium(),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: isMobile ? 12.0 : 40.0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          _navigateToAuth(context, isSignUp: false),
                      style: TextButton.styleFrom(
                        foregroundColor: _kSubtext,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      child: const Text('Login'),
                    ),
                    const SizedBox(width: 8),
                    _PrimaryButton(
                      label: 'Sign Up',
                      onTap: () =>
                          _navigateToAuth(context, isSignUp: true),
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // ── Hero ─────────────────────────────────────────────────────
              _HeroSection(
                isMobile: isMobile,
                onLearnMore: _scrollToFeatures,
                onStartTrial: () =>
                    _navigateToAuth(context, isSignUp: true),
              ),

              // ── Divider strip ────────────────────────────────────────────
              _TrustBanner(),

              const SizedBox(height: 96),

              // ── Features ─────────────────────────────────────────────────
              Container(
                key: _featuresKey,
                child: _FeaturesSection(isMobile: isMobile),
              ),

              const SizedBox(height: 96),

              // ── Inside InternLog ─────────────────────────────────────────
              _InsideInternLogSection(isMobile: isMobile),

              const SizedBox(height: 96),

              // ── How It Works ─────────────────────────────────────────────
              _HowItWorksSection(isMobile: isMobile),

              const SizedBox(height: 96),

              // ── Pricing ──────────────────────────────────────────────────
              _PricingSection(
                isMobile: isMobile,
                onGetPremium: () =>
                    _navigateToAuth(context, isSignUp: true),
              ),

              const SizedBox(height: 80),

              // ── Footer ───────────────────────────────────────────────────
              _FooterBar(
                isMobile: isMobile,
                onLogin: () => _navigateToAuth(context, isSignUp: false),
                onSignUp: () => _navigateToAuth(context, isSignUp: true),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

/// Reusable primary CTA button with Royal Blue fill.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: compact ? 14 : 16,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Constrained image wrapper — never unconstrained.
class _ConstrainedImage extends StatelessWidget {
  final String assetPath;
  final double maxHeight;
  final double? maxWidth;
  final BoxFit fit;
  final double borderRadius;

  const _ConstrainedImage({
    required this.assetPath,
    this.maxHeight = _kHeroImageMaxHeight,
    this.maxWidth,
    this.fit = BoxFit.contain,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      assetPath,
      fit: fit,
      width: maxWidth ?? double.infinity,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        maxWidth: maxWidth ?? double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      ),
    );
  }
}

// ── Hero Section ───────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onLearnMore;
  final VoidCallback onStartTrial;

  const _HeroSection({
    required this.isMobile,
    required this.onLearnMore,
    required this.onStartTrial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kSurface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: isMobile ? 64.0 : 100.0,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildCopy(textAlign: TextAlign.center),
                const SizedBox(height: 56),
                _ConstrainedImage(
                  assetPath: 'assets/images/hero_image.png',
                  maxHeight: _kHeroImageMaxHeight,
                  fit: BoxFit.contain,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    flex: 5,
                    child: _buildCopy(textAlign: TextAlign.left)),
                const SizedBox(width: 64),
                Expanded(
                  flex: 5,
                  child: _ConstrainedImage(
                    assetPath: 'assets/images/hero_image.png',
                    maxHeight: _kHeroImageMaxHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCopy({required TextAlign textAlign}) {
    final isCenter = textAlign == TextAlign.center;
    return Column(
      crossAxisAlignment:
          isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Eyebrow pill
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Text(
            '🎓 Built for Engineering Students',
            style: TextStyle(
              color: _kBlue,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Headline
        Text(
          'Master Your\nSummer Training Logs.',
          textAlign: textAlign,
          style: TextStyle(
            fontSize: isMobile ? 38 : 54,
            fontWeight: FontWeight.w900,
            height: 1.1,
            color: _kInk,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 20),

        // Sub-headline
        Text(
          'Document site work, attach photos, and generate university-ready PDF reports — instantly.',
          textAlign: textAlign,
          style: const TextStyle(
            fontSize: 18,
            height: 1.6,
            color: _kSubtext,
          ),
        ),
        const SizedBox(height: 40),

        // CTAs
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment:
              isCenter ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _PrimaryButton(
                label: 'Start 3-Day Free Trial',
                onTap: onStartTrial),
            OutlinedButton(
              onPressed: onLearnMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kInk,
                side:
                    const BorderSide(color: _kBorder, width: 1.5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
              child: const Text('See Features'),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Trust Banner ───────────────────────────────────────────────────────────────

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kSlate,
      padding:
          const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'TRUSTED BY ENGINEERING STUDENTS ACROSS MALAYSIA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSubtext,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: const [
              _TrustPill(icon: FontAwesomeIcons.checkCircle, label: 'PDF export in seconds'),
              _TrustPill(icon: FontAwesomeIcons.cloud, label: 'Cloud-synced logs'),
              _TrustPill(icon: FontAwesomeIcons.cameraRetro, label: 'Compressed site photos'),
              _TrustPill(icon: FontAwesomeIcons.wandMagicSparkles, label: 'Auto-formatted reports'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 14, color: _kBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
      ],
    );
  }
}

// ── Features Section ───────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final bool isMobile;

  const _FeaturesSection({required this.isMobile});

  static const _features = [
    _FeatureData(
      icon: FontAwesomeIcons.compress,
      title: 'Smart Image Compression',
      description:
          'Save site photos directly without hitting storage limits. Optimized automatically for clarity and size.',
    ),
    _FeatureData(
      icon: FontAwesomeIcons.filePdf,
      title: 'Instant PDF Export',
      description:
          'Generate professional daily and weekly reports with automatic layout, cover pages, and watermarks.',
    ),
    _FeatureData(
      icon: FontAwesomeIcons.cloudArrowUp,
      title: 'Cloud Sync',
      description:
          'Never lose a log. Access your data securely from any device, anywhere, anytime.',
    ),
    _FeatureData(
      icon: FontAwesomeIcons.wandMagicSparkles,
      title: 'Auto-Formatting',
      description:
          'Stop wrestling with Word docs. Focus on the site — we handle the paperwork and layout.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSlate,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
      ),
      child: Column(
        children: [
          // Section header
          Text(
            'Everything You Need',
            style: TextStyle(
              fontSize: isMobile ? 30 : 40,
              fontWeight: FontWeight.w900,
              color: _kInk,
              letterSpacing: -0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Powerful tools designed specifically for civil engineering students.',
            style: TextStyle(fontSize: 17, color: _kSubtext, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),

          // Feature cards grid
          isMobile
              ? Column(
                  children: _features
                      .map((f) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 20),
                            child: _FeatureCard(data: f),
                          ))
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(children: [
                        _FeatureCard(data: _features[0]),
                        const SizedBox(height: 20),
                        _FeatureCard(data: _features[1]),
                      ]),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(children: [
                        _FeatureCard(data: _features[2]),
                        const SizedBox(height: 20),
                        _FeatureCard(data: _features[3]),
                      ]),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;

  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(data.icon, color: _kBlue, size: 22),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: _kSubtext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inside InternLog Section ───────────────────────────────────────────────────

class _InsideInternLogSection extends StatelessWidget {
  final bool isMobile;

  const _InsideInternLogSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 80.0,
      ),
      child: Column(
        children: [
          // Row 1 – text left, image right
          _buildRow(
            context,
            text: 'Effortless site logging. Snap photos and write observations directly from the construction site.',
            assetPath: 'assets/images/add_log.png',
            imageOnRight: true,
          ),

          SizedBox(height: isMobile ? 64 : 96),

          // Row 2 – image left, text right
          _buildRow(
            context,
            text: 'Instant university-ready PDFs. Generate formatted reports in one tap, perfectly aligned with engineering standards.',
            assetPath: 'assets/images/report.png',
            imageOnRight: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String text,
    required String assetPath,
    required bool imageOnRight,
  }) {
    final textWidget = Text(
      text,
      style: TextStyle(
        fontSize: isMobile ? 26 : 36,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: _kInk,
        letterSpacing: -0.6,
      ),
    );

    final imageWidget = _ConstrainedImage(
      assetPath: assetPath,
      maxHeight: _kFeatureImageMaxHeight,
      fit: BoxFit.contain,
      borderRadius: 16,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget,
          const SizedBox(height: 32),
          imageWidget,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: imageOnRight
          ? [
              Expanded(flex: 5, child: textWidget),
              const SizedBox(width: 64),
              Expanded(flex: 5, child: imageWidget),
            ]
          : [
              Expanded(flex: 5, child: imageWidget),
              const SizedBox(width: 64),
              Expanded(flex: 5, child: textWidget),
            ],
    );
  }
}

// ── How It Works Section ───────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  final bool isMobile;

  const _HowItWorksSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(
          number: 1,
          icon: FontAwesomeIcons.cameraRetro,
          title: 'Snap & Upload',
          description:
              'Take a photo of the site or materials and attach it to your daily log.'),
      _StepData(
          number: 2,
          icon: FontAwesomeIcons.penToSquare,
          title: 'Add Observations',
          description:
              'Write your engineering notes, record weather, and log site activities.'),
      _StepData(
          number: 3,
          icon: FontAwesomeIcons.fileArrowDown,
          title: 'Export & Submit',
          description:
              'Download a polished PDF and hand it to your supervisor, same day.'),
    ];

    return Container(
      color: _kSlate,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 80.0,
      ),
      child: Column(
        children: [
          Text(
            'From Site to Report in Minutes',
            style: TextStyle(
              fontSize: isMobile ? 30 : 40,
              fontWeight: FontWeight.w900,
              color: _kInk,
              letterSpacing: -0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Three steps. No clutter. No Word documents.',
            style: TextStyle(fontSize: 17, color: _kSubtext),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          isMobile
              ? Column(
                  children: steps
                      .map((s) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 40),
                            child: _StepCard(data: s),
                          ))
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps
                      .expand((s) => [
                            Expanded(child: _StepCard(data: s)),
                            if (s != steps.last)
                              const SizedBox(width: 32),
                          ])
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _StepData data;

  const _StepCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Step number chip
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _kNavy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '0${data.number}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Icon circle
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEFF6FF),
            border:
                Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
          ),
          child: Center(
              child: FaIcon(data.icon, size: 28, color: _kBlue)),
        ),
        const SizedBox(height: 20),

        Text(
          data.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          data.description,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: _kSubtext,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Pricing Section ────────────────────────────────────────────────────────────

class _PricingSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onGetPremium;

  const _PricingSection(
      {required this.isMobile, required this.onGetPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 80.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            padding:
                EdgeInsets.all(isMobile ? 36 : 56),
            decoration: BoxDecoration(
              color: _kNavy,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x401E3A8A),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SIMPLE PRICING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Start free. Go premium for one summer.',
                  style: TextStyle(
                    fontSize: isMobile ? 26 : 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  'Unlock unlimited logs, PDF exports, and cloud sync for a single one-time payment — just for your internship season.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Price display
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(children: [
                    TextSpan(
                      text: '\$5',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -2,
                      ),
                    ),
                    TextSpan(
                      text: '  one-time',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFFBAD4FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 36),

                ElevatedButton(
                  onPressed: onGetPremium,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Get Premium Access'),
                ),
                const SizedBox(height: 16),
                Text(
                  '3-day free trial included · No subscription',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────────

class _FooterBar extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;

  const _FooterBar({
    required this.isMobile,
    required this.onLogin,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kInk,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 80.0,
        vertical: 36.0,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const InternLogLogo.medium(),
                const SizedBox(height: 16),
                _copyright(),
                const SizedBox(height: 20),
                _links(context),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InternLogLogo.medium(),
                    const SizedBox(height: 8),
                    _copyright(),
                  ],
                ),
                _links(context),
              ],
            ),
    );
  }

  Widget _copyright() {
    return const Text(
      '© 2026 InternLog. All rights reserved.',
      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
    );
  }

  Widget _links(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF94A3B8)),
          child: const Text('Login',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onSignUp,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('Sign Up',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Data Models ────────────────────────────────────────────────────────────────

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _StepData {
  final int number;
  final IconData icon;
  final String title;
  final String description;

  const _StepData({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });
}