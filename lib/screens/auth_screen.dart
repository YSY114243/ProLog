import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/intern_log_logo.dart';
import '../core/app_colors.dart';
import '../services/supabase_service.dart';
import 'dashboard_screen.dart';
import 'paywall_screen.dart';
import 'supervisor_dashboard_screen.dart';

/// Full-screen authentication flow — supports both Login and Sign Up.
///
/// On desktop renders a split-screen layout (brand panel left, form right).
/// On mobile renders a single-column scrollable form.
///
/// On successful auth calls [Navigator.pushAndRemoveUntil] to [DashboardScreen],
/// clearing the back-stack so the user cannot navigate back to this screen.
class AuthScreen extends StatefulWidget {
  /// Whether to start in Sign-Up mode (`true`) or Login mode (`false`).
  final bool initialIsSignUp;
  /// If true, navigates to the Paywall immediately after successful auth.
  final bool intentToPurchase;

  const AuthScreen({
    super.key,
    this.initialIsSignUp = false,
    this.intentToPurchase = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool   _isSignUp;
  bool        _isSupervisorSignUp = false;
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passCtrl       = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();
  bool    _obscure   = true;
  bool    _loading   = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    final name   = _nameCtrl.text.trim();
    final email  = _emailCtrl.text.trim();
    final pass   = _passCtrl.text;
    final client = Supabase.instance.client;

    try {
      if (_isSignUp) {
        if (_isSupervisorSignUp) {
          await SupabaseService.instance.registerSupervisor(email, pass, name);
          if (mounted) _toDashboard();
        } else {
          final res = await client.auth.signUp(
            email: email,
            password: pass,
            data: {'full_name': name},
          );
          if (!mounted) return;
          if (res.user != null) {
            _toDashboard();
          } else {
            setState(() => _errorMsg = 'Check your email to confirm your account, then sign in.');
          }
        }
      } else {
        await client.auth.signInWithPassword(email: email, password: pass);
        if (mounted) _toDashboard();
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMsg = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toDashboard() async {
    final user = Supabase.instance.client.auth.currentUser;
    bool showPaywall = widget.intentToPurchase;
    if (user != null && !showPaywall) {
      final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
      final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
      final isPremium = user.userMetadata?['is_premium'] == true;
      if (daysSinceCreation > 3 && !isPremium) {
        showPaywall = true;
      }
    }

    if (showPaywall) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PaywallScreen(isVoluntary: widget.intentToPurchase)),
        (route) => false,
      );
      return;
    }

    final role = await SupabaseService.instance.fetchUserRole();
    if (!mounted) return;

    if (role == 'supervisor') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SupervisorDashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _toggleMode() => setState(() {
        _isSignUp  = !_isSignUp;
        _isSupervisorSignUp = false;
        _errorMsg  = null;
        _formKey.currentState?.reset();
      });

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: isDesktop
          ? Row(
              children: [
                Expanded(child: _BrandPanel()),
                SizedBox(
                  width: 500,
                  child: _FormPanel(
                    isSignUp: _isSignUp,
                    isSupervisorSignUp: _isSupervisorSignUp,
                    formKey: _formKey,
                    nameCtrl: _nameCtrl,
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    inviteCodeCtrl: _inviteCodeCtrl,
                    obscure: _obscure,
                    loading: _loading,
                    errorMsg: _errorMsg,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    onSubmit: _submit,
                    onToggleMode: _toggleMode,
                    onToggleSupervisorMode: (v) => setState(() => _isSupervisorSignUp = v ?? false),
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ],
            )
          : _FormPanel(
              isSignUp: _isSignUp,
              isSupervisorSignUp: _isSupervisorSignUp,
              formKey: _formKey,
              nameCtrl: _nameCtrl,
              emailCtrl: _emailCtrl,
              passCtrl: _passCtrl,
              inviteCodeCtrl: _inviteCodeCtrl,
              obscure: _obscure,
              loading: _loading,
              errorMsg: _errorMsg,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
              onToggleMode: _toggleMode,
              onToggleSupervisorMode: (v) => setState(() => _isSupervisorSignUp = v ?? false),
              onBack: () => Navigator.pop(context),
            ),
    );
  }
}

// ── Brand panel (desktop left) ────────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentRoyalBlue, AppColors.primaryDeepNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -90, right: -90,
            child: _Blob(300, Theme.of(context).colorScheme.surface.withValues(alpha: 0.07)),
          ),
          Positioned(
            bottom: -120, left: -60,
            child: _Blob(380, Theme.of(context).colorScheme.surface.withValues(alpha: 0.05)),
          ),
          Positioned(
            top: 200, left: -60,
            child: _Blob(200, Theme.of(context).colorScheme.surface.withValues(alpha: 0.04)),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                _WhiteLogo(),

                const Spacer(),

                // Headline
                Text(
                  'Internship\nDocumentation\nMade Simple.',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.surface,
                    height: 1.12,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Log daily tasks, track field issues, and auto-generate\nyour final PDF report — all in one place.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
                    height: 1.65,
                  ),
                ),

                const SizedBox(height: 44),

                // Feature bullets
                ...[
                  (Icons.bolt_rounded,            'Log daily tasks in under 5 minutes'),
                  (Icons.picture_as_pdf_rounded,  'Auto-generate professional PDF reports'),
                  (Icons.cloud_done_rounded,       'Securely synced to the cloud'),
                  (Icons.track_changes_rounded,    'Issue & solution tracking built-in'),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(item.$1, color: Theme.of(context).colorScheme.surface, size: 15),
                        ),
                        const SizedBox(width: 13),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                Text(
                  '© ${DateTime.now().year} InternLog  ·  Engineering Internship Platform',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
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

class _WhiteLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const InternLogLogo.large(light: true);
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ── Form panel ────────────────────────────────────────────────────────────────

class _FormPanel extends StatelessWidget {
  final bool isSignUp;
  final bool isSupervisorSignUp;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController inviteCodeCtrl;
  final bool obscure;
  final bool loading;
  final String? errorMsg;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final ValueChanged<bool?> onToggleSupervisorMode;
  final VoidCallback onBack;

  const _FormPanel({
    required this.isSignUp,
    required this.isSupervisorSignUp,
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.inviteCodeCtrl,
    required this.obscure,
    required this.loading,
    required this.errorMsg,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onToggleSupervisorMode,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              onPressed: onBack,
              padding: EdgeInsets.zero,
              tooltip: 'Back',
            ),
            const SizedBox(height: 36),

            // Title
            Text(
              isSignUp ? 'Create your account' : 'Welcome back',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSignUp
                  ? 'Start documenting your internship in under a minute.'
                  : 'Sign in to continue to your dashboard.',
              style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                  height: 1.5),
            ),
            const SizedBox(height: 36),

            // Error banner
            if (errorMsg != null) ...[
              _ErrorBanner(errorMsg!),
              const SizedBox(height: 20),
            ],

            // Form
            Form(
              key: formKey,
              child: Column(
                children: [
                  if (isSignUp) ...[
                    _Field(
                      controller: nameCtrl,
                      label: 'Full Name',
                      hint: 'John Doe',
                      icon: Icons.person_outline_rounded,
                      type: TextInputType.name,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.lock, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Feature Locked'),
                              ],
                            ),
                            content: const Text('The Supervisor Portal is currently under final testing and will be unlocked in the upcoming update.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSupervisorSignUp 
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSupervisorSignUp 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.business_center, 
                                color: isSupervisorSignUp 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Are you a Company Supervisor?', 
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          color: isSupervisorSignUp 
                                              ? Theme.of(context).colorScheme.primary 
                                              : Colors.black87)),
                                  Text(isSupervisorSignUp ? 'Supervisor mode enabled.' : 'Register here to evaluate trainees.', 
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            if (isSupervisorSignUp)
                              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _Field(
                    controller: emailCtrl,
                    label: 'Email Address',
                    hint: 'you@university.edu',
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!v.contains('@')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    controller: passCtrl,
                    label: 'Password',
                    hint: isSignUp ? 'At least 6 characters' : 'Your password',
                    icon: Icons.lock_outline_rounded,
                    obscure: obscure,
                    suffix: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
                        size: 20,
                      ),
                      onPressed: onToggleObscure,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (isSignUp && v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        disabledBackgroundColor:
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: loading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.surface, strokeWidth: 2.5),
                            )
                          : Text(
                              isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Toggle mode
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isSignUp
                        ? 'Already have an account? '
                        : "Don't have an account? ",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: onToggleMode,
                    child: Text(
                      isSignUp ? 'Sign In' : 'Sign Up',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.redAccent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable form field ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? type;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.type,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              letterSpacing: 0.2),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          validator: validator,
          style:
              TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey, fontSize: 14),
            prefixIcon:
                Icon(icon, size: 19, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
            suffixIcon: suffix,
            filled: true,
            fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColors.borderSubtle, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}