import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'landing_screen.dart';
import 'paywall_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _formKey = GlobalKey<FormState>();

  final _uniIdCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _uniNameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _supervisorCtrl = TextEditingController();

  String? _customLogoUrl;
  bool _isSaving = false;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  void _loadMetadata() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      final meta = user.userMetadata!;
      _uniIdCtrl.text = meta['uni_id'] ?? '';
      _majorCtrl.text = meta['major'] ?? '';
      _uniNameCtrl.text = meta['uni_name'] ?? '';
      _companyCtrl.text = meta['company'] ?? '';
      _supervisorCtrl.text = meta['supervisor'] ?? '';
      _customLogoUrl = meta['custom_logo_url'];
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'uni_id': _uniIdCtrl.text.trim(),
            'major': _majorCtrl.text.trim(),
            'uni_name': _uniNameCtrl.text.trim(),
            'company': _companyCtrl.text.trim(),
            'supervisor': _supervisorCtrl.text.trim(),
          },
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully.'),
            backgroundColor: AppTheme.primaryCyan,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploadingLogo = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final user = Supabase.instance.client.auth.currentUser!;
      final ext = pickedFile.name.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${user.id}/logo_$timestamp.$ext';

      // Upload using SupabaseService
      final url = await SupabaseService.instance.uploadImage(path, bytes);

      // Save to metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'custom_logo_url': url}),
      );

      if (mounted) {
        setState(() => _customLogoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo uploaded successfully.'),
            backgroundColor: AppTheme.primaryCyan,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload logo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (r) => false,
      );
    }
  }

  @override
  void dispose() {
    _uniIdCtrl.dispose();
    _majorCtrl.dispose();
    _uniNameCtrl.dispose();
    _companyCtrl.dispose();
    _supervisorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isPremium = user?.userMetadata?['is_premium'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Academic Profile Section ─────────────────────────────────────
              const Text(
                'Academic Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These details are used to automatically generate your final university PDF report.',
                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField('University ID', _uniIdCtrl, Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _buildTextField('Major (e.g., Civil Engineering)', _majorCtrl, Icons.school_outlined),
                      const SizedBox(height: 16),
                      _buildTextField('University Name', _uniNameCtrl, Icons.account_balance_outlined),
                      const SizedBox(height: 16),
                      _buildTextField('Training Company', _companyCtrl, Icons.business_outlined),
                      const SizedBox(height: 16),
                      _buildTextField('Supervisor Name', _supervisorCtrl, Icons.person_outline_rounded),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryCyan,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Profile',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Report Customization ───────────────────────────────────────
              const Text(
                'Report Customization',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add a custom logo to your PDF report header and watermark.',
                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isUploadingLogo 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryCyan))
                      : const Icon(Icons.image_rounded, color: AppTheme.primaryCyan),
                  ),
                  title: Text(
                    _customLogoUrl != null ? 'Update Custom Logo' : 'Upload Custom Logo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    _customLogoUrl != null ? 'A logo is currently active.' : 'No logo uploaded.',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  onTap: _isUploadingLogo ? null : _uploadLogo,
                ),
              ),

              const SizedBox(height: 40),

              // ── Subscription Section ─────────────────────────────────────────
              if (!isPremium) ...[
                const Text(
                  'Subscription',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryCyan),
                    ),
                    title: const Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Unlock custom PDF logos and remove all trial limits.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PaywallScreen(isVoluntary: true)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],

              // ── Account Section ──────────────────────────────────────────────
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Sign out of your account on this device.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  onTap: _logout,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.cyanLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0ECF0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryCyan, width: 1.5),
        ),
      ),
    );
  }
}
