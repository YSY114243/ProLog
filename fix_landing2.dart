import 'dart:io';

void main() {
  final file = File(r'C:\Projects\Professional Log\lib\screens\landing_screen.dart');
  String content = file.readAsStringSync();

  // Replace colors inside the file
  content = content.replaceAll('_kPrimaryIndigo', 'Theme.of(context).colorScheme.primary');
  content = content.replaceAll('_kSecondaryIndigo', 'Theme.of(context).colorScheme.secondary');
  content = content.replaceAll('_kLightBackground', 'Theme.of(context).scaffoldBackgroundColor');
  content = content.replaceAll('_kDarkText', 'Theme.of(context).colorScheme.onSurface');
  content = content.replaceAll('_kMutedText', 'Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey');
  
  content = content.replaceAll('Colors.white70', 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)');
  content = content.replaceAll('Colors.white', 'Theme.of(context).colorScheme.surface');

  // Strip const keywords specifically for the methods we touched, or just globally remove `const ` before `Theme.of`
  final lines = content.split('\n');
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('Theme.of(context)')) {
      lines[i] = lines[i].replaceAll(RegExp(r'\bconst\s+'), '');
    }
  }
  content = lines.join('\n');

  // Remove the static constants block at the top
  final lines2 = content.split('\n');
  lines2.removeWhere((line) => line.contains('// Modern SaaS Colors') || 
                               line.contains('Color _kPrimaryIndigo') ||
                               line.contains('Color _kSecondaryIndigo') ||
                               line.contains('Color _kLightBackground') ||
                               line.contains('Color _kDarkText') ||
                               line.contains('Color _kMutedText') ||
                               line.contains('Color Theme.of(context)') ||
                               line.contains('const Color _kLightBackground'));

  // Fix method signatures to pass context
  content = lines2.join('\n');
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

  // Corrected _buildStep replacements
  content = content.replaceAll('Widget _buildStep(int number, IconData icon, String title, String description)', 'Widget _buildStep(BuildContext context, int number, IconData icon, String title, String description)');
  content = content.replaceAll('_buildStep(1,', '_buildStep(context, 1,');
  content = content.replaceAll('_buildStep(2,', '_buildStep(context, 2,');
  content = content.replaceAll('_buildStep(3,', '_buildStep(context, 3,');
  
  // Strip const from Widget trees that call methods with context now (since they are no longer pure const functions)
  final lines3 = content.split('\n');
  for (int i = 0; i < lines3.length; i++) {
    if (lines3[i].contains('_buildFeatureCard') || 
        lines3[i].contains('_buildStep') || 
        lines3[i].contains('_buildCopy') || 
        lines3[i].contains('_buildMockup') || 
        lines3[i].contains('_buildPricingCard') || 
        lines3[i].contains('_buildFooterLinks')) {
      // Find nearest const
      for (int j = i; j >= 0 && j > i - 10; j--) {
        if (lines3[j].contains('const ')) {
          lines3[j] = lines3[j].replaceFirst(RegExp(r'\bconst\s+'), '');
        }
      }
    }
    
    // Some BoxDecoration arrays or nested Text widgets
    if (lines3[i].contains('Theme.of(context)')) {
      for (int j = i; j >= 0 && j > i - 10; j--) {
        if (lines3[j].contains('const ')) {
          lines3[j] = lines3[j].replaceFirst(RegExp(r'\bconst\s+'), '');
        }
      }
    }
  }

  file.writeAsStringSync(lines3.join('\n'));
}
