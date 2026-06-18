import 'package:flutter/material.dart';
import '../models/daily_log.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

/// The public-facing landing page shown when the user is not signed in.
///
/// Sections:
///   1. Sticky [_NavBar]
///   2. [_HeroSection] — animated headline + app mockup preview
///   3. [_FeaturesSection] — three feature cards
///   4. [_StatsStrip] — gradient strip with key stats
///   5. [_CtaSection] — bottom call-to-action card
///   6. [_FooterBar]
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heroCtrl;
  late final Animation<double>   _heroFade;
  late final Animation<Offset>   _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _heroFade  = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  void _goAuth({bool signUp = false}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            AuthScreen(initialIsSignUp: signUp),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle radial background accents (pointer events ignored)
          _BackgroundAccents(),

          CustomScrollView(
            slivers: [
              // ── Sticky NavBar ─────────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _NavDelegate(
                  onLogin:  () => _goAuth(),
                  onSignUp: () => _goAuth(signUp: true),
                  isMobile: isMobile,
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── Hero ─────────────────────────────────────────────
                    FadeTransition(
                      opacity: _heroFade,
                      child: SlideTransition(
                        position: _heroSlide,
                        child: _HeroSection(
                          isMobile: isMobile,
                          onGetStarted: () => _goAuth(signUp: true),
                        ),
                      ),
                    ),

                    // ── Features ─────────────────────────────────────────
                    _FeaturesSection(isMobile: isMobile),

                    // ── Stats ─────────────────────────────────────────────
                    _StatsStrip(isMobile: isMobile),

                    // ── CTA ───────────────────────────────────────────────
                    _CtaSection(
                      onSignUp: () => _goAuth(signUp: true),
                      isMobile: isMobile,
                    ),

                    // ── Footer ────────────────────────────────────────────
                    _FooterBar(isMobile: isMobile),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Background decorative accents ─────────────────────────────────────────────

class _BackgroundAccents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -120, right: -120,
              child: _RadialBlob(520, AppTheme.primaryCyan.withValues(alpha: 0.07)),
            ),
            Positioned(
              top: 500, left: -180,
              child: _RadialBlob(440, AppTheme.accentTeal.withValues(alpha: 0.05)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadialBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _RadialBlob(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

// ── Sticky NavBar ─────────────────────────────────────────────────────────────

class _NavDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final bool isMobile;

  _NavDelegate({
    required this.onLogin,
    required this.onSignUp,
    required this.isMobile,
  });

  @override double get minExtent => 68;
  @override double get maxExtent => 68;

  @override
  Widget build(
      BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(
            bottom: BorderSide(color: Color(0xFFE0F7FA), width: 1)),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 64, vertical: 0),
        child: Row(
          children: [
            _ProLogLogo(),

            if (!isMobile) ...[
              const SizedBox(width: 48),
              _HoverLink('Features'),
              const SizedBox(width: 32),
              _HoverLink('About'),
            ],

            const Spacer(),

            // Login ghost button
            TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              child: const Text('Login',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),

            // Sign Up filled button
            ElevatedButton(
              onPressed: onSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign Up',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _NavDelegate old) =>
      old.isMobile != isMobile;
}

// ── ProLog logo widget ────────────────────────────────────────────────────────

class _ProLogLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryCyan, AppTheme.accentTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.construction_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'ProLog',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
        ],
      );
}

// ── Hover nav link ────────────────────────────────────────────────────────────

class _HoverLink extends StatefulWidget {
  final String label;
  const _HoverLink(this.label);

  @override
  State<_HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<_HoverLink> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: Text(
        widget.label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _hov ? AppTheme.primaryCyan : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onGetStarted;

  const _HeroSection({
    required this.isMobile,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 24.0 : 80.0;

    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 64),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroText(isMobile: true, onGetStarted: onGetStarted),
                const SizedBox(height: 52),
                Center(child: _AppMockup()),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _HeroText(
                      isMobile: false, onGetStarted: onGetStarted),
                ),
                const SizedBox(width: 56),
                _AppMockup(),
              ],
            ),
    );
  }
}

// ── Hero text block ───────────────────────────────────────────────────────────

class _HeroText extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onGetStarted;
  const _HeroText({required this.isMobile, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pill badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.primaryCyan.withValues(alpha: 0.25)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 13, color: AppTheme.primaryCyan),
              SizedBox(width: 6),
              Text(
                'For Civil Engineering Interns',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryCyan,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Main headline
        Text(
          'Your Internship.\nDocumented.\nProfessionally.',
          style: TextStyle(
            fontSize: isMobile ? 40 : 54,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            height: 1.12,
            letterSpacing: -1.8,
          ),
        ),
        const SizedBox(height: 20),

        // Subtitle
        Text(
          'Stop spending hours on your final report. ProLog lets civil engineering students log daily tasks in minutes, then generates a professional PDF report automatically.',
          style: TextStyle(
            fontSize: isMobile ? 15 : 17,
            color: AppTheme.textSecondary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 36),

        // CTA buttons
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: onGetStarted,
              icon: const Icon(Icons.rocket_launch_rounded, size: 17),
              label: const Text('Get Started Free',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 17),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_circle_outline_rounded, size: 17),
              label: const Text('See Features',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: Color(0xFFD0ECF0)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 17),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // Trust signals
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: const [
            _Trust('Free to use'),
            _Trust('No credit card'),
            _Trust('Instant setup'),
          ],
        ),
      ],
    );
  }
}

class _Trust extends StatelessWidget {
  final String label;
  const _Trust(this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 15, color: Color(0xFF43A047)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMuted)),
        ],
      );
}

// ── App Mockup Preview ────────────────────────────────────────────────────────

class _AppMockup extends StatelessWidget {
  static const _entries = [
    ('Jun 15', 'Field Work', 'Supervised concrete pouring at Block D, monitored mix ratio'),
    ('Jun 14', 'Office Work', 'Prepared quantity survey for north wing extension phase 2'),
    ('Jun 13', 'Software', 'Updated AutoCAD drawings for drainage system layout'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCyan.withValues(alpha: 0.14),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFD8F5F9), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Chrome header ──────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE0F7FA))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryCyan, AppTheme.accentTeal],
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text('ProLog',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                const Icon(Icons.add_circle_rounded,
                    color: AppTheme.primaryCyan, size: 19),
                const SizedBox(width: 8),
                const Icon(Icons.picture_as_pdf_rounded,
                    color: AppTheme.textMuted, size: 19),
              ],
            ),
          ),

          // ── Mini stats row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                _MiniStat('12', 'Total',  AppTheme.primaryCyan),
                const SizedBox(width: 7),
                _MiniStat('7',  'Field',  TaskType.fieldWork.color),
                const SizedBox(width: 7),
                _MiniStat('3',  'Office', TaskType.officeWork.color),
                const SizedBox(width: 7),
                _MiniStat('2',  'Software',TaskType.software.color),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Log entry previews ──────────────────────────────────────────
          for (var i = 0; i < _entries.length; i++)
            _MockEntry(
              date: _entries[i].$1,
              type: _entries[i].$2,
              desc: _entries[i].$3,
              highlight: i == 0,
            ),

          // ── PDF button row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F7FA), Color(0xFFE8F5E9)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB2EBF2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded,
                      color: AppTheme.primaryCyan, size: 15),
                  SizedBox(width: 7),
                  Text('Download Final Report',
                      style: TextStyle(
                          color: AppTheme.primaryCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _MockEntry extends StatelessWidget {
  final String date;
  final String type;
  final String desc;
  final bool highlight;
  const _MockEntry(
      {required this.date,
      required this.type,
      required this.desc,
      required this.highlight});

  Color get _typeColor {
    if (type == 'Field Work')  return TaskType.fieldWork.color;
    if (type == 'Office Work') return TaskType.officeWork.color;
    return TaskType.software.color;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFE8FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppTheme.primaryCyan.withValues(alpha: 0.28)
              : const Color(0xFFE0F7FA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(date,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(type,
                    style: TextStyle(
                        fontSize: 9,
                        color: _typeColor,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(desc,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Features Section ──────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final bool isMobile;
  const _FeaturesSection({required this.isMobile});

  static const _cards = [
    _FData(
      icon: Icons.edit_note_rounded,
      title: '5-Minute Daily Logging',
      body: 'Log task type, description, and issues in seconds. Date picker, choice chips, and smart validation keep the form fast and frictionless.',
      accent: AppTheme.primaryCyan,
      bg:    Color(0xFFE0F7FA),
    ),
    _FData(
      icon: Icons.picture_as_pdf_rounded,
      title: 'One-Click PDF Report',
      body: 'Generate a professional, academic-style internship report instantly. Cover page, student info, and a full activity table — all formatted for you.',
      accent: Color(0xFF5C6BC0),
      bg:    Color(0xFFEDE7F6),
    ),
    _FData(
      icon: Icons.track_changes_rounded,
      title: 'Issue & Solution Tracking',
      body: 'Every problem you face on-site gets documented alongside its solution. Demonstrate initiative and technical growth to your supervisor.',
      accent: Color(0xFF26A69A),
      bg:    Color(0xFFE0F2F1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6FDFE),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 88),
      child: Column(
        children: [
          // Tag pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'FEATURES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryCyan,
                letterSpacing: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Everything you need to\nace your internship',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 30 : 42,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.18,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Built specifically for civil engineering students who want to impress\ntheir supervisors and simplify their final report.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: AppTheme.textSecondary, height: 1.65),
          ),
          const SizedBox(height: 60),

          // Cards grid
          isMobile
              ? Column(
                  children: _cards
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _FeatureCard(data: c),
                          ))
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _cards.asMap().entries.map((e) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left:  e.key == 0 ? 0 : 12,
                          right: e.key == 2 ? 0 : 12,
                        ),
                        child: _FeatureCard(data: e.value),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

class _FData {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final Color bg;
  const _FData({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.bg,
  });
}

class _FeatureCard extends StatefulWidget {
  final _FData data;
  const _FeatureCard({required this.data});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform:
            Matrix4.translationValues(0, _hov ? -7 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hov
                ? d.accent.withValues(alpha: 0.35)
                : const Color(0xFFE0F7FA),
          ),
          boxShadow: [
            BoxShadow(
              color: _hov
                  ? d.accent.withValues(alpha: 0.11)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hov ? 28 : 10,
              offset: Offset(0, _hov ? 10 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: d.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(d.icon, color: d.accent, size: 28),
            ),
            const SizedBox(height: 22),
            Text(d.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.3)),
            const SizedBox(height: 11),
            Text(d.body,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.7)),
          ],
        ),
      ),
    );
  }
}

// ── Stats strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final bool isMobile;
  const _StatsStrip({required this.isMobile});

  static const _stats = [
    ('5 min', 'To log a daily entry'),
    ('1-click', 'PDF report generation'),
    ('∞', 'Logs you can store'),
    ('100%', 'Formatting automated'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: isMobile
          ? GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              children: _stats.map((s) => _Stat(s.$1, s.$2)).toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _stats.map((s) => _Stat(s.$1, s.$2)).toList(),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                  letterSpacing: -1)),
          const SizedBox(height: 7),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.78))),
        ],
      );
}

// ── CTA section ───────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  final VoidCallback onSignUp;
  final bool isMobile;
  const _CtaSection({required this.onSignUp, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6FDFE),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 80),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 28 : 60, vertical: 60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD0ECF0)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryCyan.withValues(alpha: 0.07),
              blurRadius: 48,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF009688)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to simplify\nyour internship?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 28 : 38,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.2,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Join students who log smarter, not harder.\nCreate your account in under 60 seconds — no credit card needed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.65),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: onSignUp,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Create Free Account',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 34, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _FooterBar extends StatelessWidget {
  final bool isMobile;
  const _FooterBar({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 64, vertical: 22),
      decoration: const BoxDecoration(
          border:
              Border(top: BorderSide(color: Color(0xFFE0F7FA)))),
      child: isMobile
          ? Column(
              children: [
                _ProLogLogo(),
                const SizedBox(height: 12),
                Text(
                  '© ${DateTime.now().year} ProLog. Built for Civil Engineering Students.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            )
          : Row(
              children: [
                _ProLogLogo(),
                const Spacer(),
                Text(
                  '© ${DateTime.now().year} ProLog  ·  Built for Civil Engineering Students.',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
    );
  }
}
