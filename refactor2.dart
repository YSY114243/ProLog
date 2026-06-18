import 'dart:io';

void main() {
  final file = File(r'C:\Projects\Professional Log\lib\screens\landing_screen.dart');
  String content = file.readAsStringSync();
  
  // Remove the static declarations
  content = content.replaceAll(RegExp(r'Color _kPrimaryIndigo = .*\n'), '');
  content = content.replaceAll(RegExp(r'Color _kSecondaryIndigo = .*\n'), '');
  content = content.replaceAll(RegExp(r'const Color _kLightBackground = .*\n'), '');
  content = content.replaceAll(RegExp(r'Color _kDarkText = .*\n'), '');
  content = content.replaceAll(RegExp(r'Color _kMutedText = .*\n'), '');

  // Replace usages inline
  content = content.replaceAll('_kPrimaryIndigo', 'Theme.of(context).colorScheme.primary');
  content = content.replaceAll('_kSecondaryIndigo', 'Theme.of(context).colorScheme.secondary');
  content = content.replaceAll('_kLightBackground', 'Theme.of(context).colorScheme.surface');
  content = content.replaceAll('_kDarkText', 'Theme.of(context).colorScheme.onSurface');
  content = content.replaceAll('_kMutedText', 'Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey');
  
  // Fix the surface70 typo
  content = content.replaceAll('Theme.of(context).colorScheme.surface70', 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)');

  file.writeAsStringSync(content);
}
