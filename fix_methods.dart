import 'dart:io';

void main() {
  final file = File(r'C:\Projects\Professional Log\lib\screens\landing_screen.dart');
  String content = file.readAsStringSync();
  
  // Fix _buildFeatureCard
  content = content.replaceAll('Widget _buildFeatureCard(_FeatureData f)', 'Widget _buildFeatureCard(BuildContext context, _FeatureData f)');
  
  // Fix _buildStep
  content = content.replaceAll('Widget _buildStep(int stepNumber, IconData icon, String title, String description)', 'Widget _buildStep(BuildContext context, int stepNumber, IconData icon, String title, String description)');
  // We already replaced the calls earlier, let's just make sure they aren't double replaced.
  // Actually, wait, let's revert the double replacements of _buildStep if they happened.
  content = content.replaceAll('_buildStep(context, context,', '_buildStep(context,');

  file.writeAsStringSync(content);
}
