import 'dart:io';

void main() {
  final file = File(r'C:\Projects\Professional Log\lib\screens\landing_screen.dart');
  String content = file.readAsStringSync();
  
  // 1. Remove Top-Level Constants completely
  content = content.replaceFirst(RegExp(r'const Color _kPrimaryIndigo = AppTheme\.primaryCyan;\s*'), '');
  content = content.replaceFirst(RegExp(r'const Color _kSecondaryIndigo = AppTheme\.accentTeal;\s*'), '');
  content = content.replaceFirst(RegExp(r'const Color _kLightBackground = Color\(0xFFF9FAFB\);\s*//.*?\n'), '');
  content = content.replaceFirst(RegExp(r'const Color _kDarkText = AppTheme\.textPrimary;\s*'), '');
  content = content.replaceFirst(RegExp(r'const Color _kMutedText = AppTheme\.textSecondary;\s*'), '');

  // 2. Add BuildContext to every private method that doesn't have it but needs Theme
  content = content.replaceAll('Widget _buildCopy({required TextAlign textAlign})', 'Widget _buildCopy(BuildContext context, {required TextAlign textAlign})');
  content = content.replaceAll('_buildCopy(textAlign: TextAlign.center)', '_buildCopy(context, textAlign: TextAlign.center)');
  content = content.replaceAll('_buildCopy(textAlign: TextAlign.left)', '_buildCopy(context, textAlign: TextAlign.left)');
  
  content = content.replaceAll('Widget _buildMockup()', 'Widget _buildMockup(BuildContext context)');
  content = content.replaceAll('_buildMockup()', '_buildMockup(context)');

  content = content.replaceAll('Widget _buildFeatureCard(_FeatureData f)', 'Widget _buildFeatureCard(BuildContext context, _FeatureData f)');
  content = content.replaceAll('_buildFeatureCard(f)', '_buildFeatureCard(context, f)');

  content = content.replaceAll('Widget _buildPricingCard(bool isMobile)', 'Widget _buildPricingCard(BuildContext context, bool isMobile)');
  content = content.replaceAll('_buildPricingCard(isMobile)', '_buildPricingCard(context, isMobile)');

  content = content.replaceAll('Widget _buildFooterLinks()', 'Widget _buildFooterLinks(BuildContext context)');
  content = content.replaceAll('_buildFooterLinks()', '_buildFooterLinks(context)');

  content = content.replaceAll('Widget _buildStep(int stepNumber, IconData icon, String title, String description)', 'Widget _buildStep(BuildContext context, int stepNumber, IconData icon, String title, String description)');
  content = content.replaceAll('_buildStep(1,', '_buildStep(context, 1,');
  content = content.replaceAll('_buildStep(2,', '_buildStep(context, 2,');
  content = content.replaceAll('_buildStep(3,', '_buildStep(context, 3,');

  // 3. Replace the _k Colors with Theme data
  content = content.replaceAll('_kPrimaryIndigo', 'Theme.of(context).colorScheme.primary');
  content = content.replaceAll('_kSecondaryIndigo', 'Theme.of(context).colorScheme.secondary');
  content = content.replaceAll('_kLightBackground', 'Theme.of(context).scaffoldBackgroundColor');
  content = content.replaceAll('_kDarkText', 'Theme.of(context).colorScheme.onSurface');
  content = content.replaceAll('_kMutedText', 'Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey');
  
  // 4. Strip const from anywhere that Theme is used
  // We can do this simply by removing 'const ' from lines containing Theme.of
  final lines = content.split('\n');
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('Theme.of(context)')) {
      lines[i] = lines[i].replaceAll(RegExp(r'\bconst\s+'), '');
    }
  }

  // 5. Hardcoded colors that might still exist
  content = lines.join('\n');
  content = content.replaceAll('Colors.white', 'Theme.of(context).colorScheme.surface');
  content = content.replaceAll('Colors.white70', 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)');

  // Run the const stripping again just in case
  final lines2 = content.split('\n');
  for (int i = 0; i < lines2.length; i++) {
    if (lines2[i].contains('Theme.of(context)')) {
      lines2[i] = lines2[i].replaceAll(RegExp(r'\bconst\s+'), '');
    }
  }

  file.writeAsStringSync(lines2.join('\n'));
}
