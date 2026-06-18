import 'dart:io';

void main() {
  final file = File(r'C:\Projects\Professional Log\lib\screens\landing_screen.dart');
  String content = file.readAsStringSync();
  
  // Add BuildContext to methods that need it
  content = content.replaceAll('Widget _buildCopy({required TextAlign textAlign})', 'Widget _buildCopy(BuildContext context, {required TextAlign textAlign})');
  content = content.replaceAll('_buildCopy(textAlign: TextAlign.center)', '_buildCopy(context, textAlign: TextAlign.center)');
  content = content.replaceAll('_buildCopy(textAlign: TextAlign.left)', '_buildCopy(context, textAlign: TextAlign.left)');
  
  content = content.replaceAll('Widget _buildMockup()', 'Widget _buildMockup(BuildContext context)');
  content = content.replaceAll('_buildMockup()', '_buildMockup(context)');

  content = content.replaceAll('Widget _buildFeatureCard(Feature f)', 'Widget _buildFeatureCard(BuildContext context, Feature f)');
  content = content.replaceAll('_buildFeatureCard(f)', '_buildFeatureCard(context, f)');

  content = content.replaceAll('Widget _buildPricingCard(bool isMobile)', 'Widget _buildPricingCard(BuildContext context, bool isMobile)');
  content = content.replaceAll('_buildPricingCard(isMobile)', '_buildPricingCard(context, isMobile)');

  content = content.replaceAll('Widget _buildFooterLinks()', 'Widget _buildFooterLinks(BuildContext context)');
  content = content.replaceAll('_buildFooterLinks()', '_buildFooterLinks(context)');

  content = content.replaceAll('Widget _buildStep(int stepNumber, IconData icon, String title, String description)', 'Widget _buildStep(BuildContext context, int stepNumber, IconData icon, String title, String description)');
  content = content.replaceAll('_buildStep(1,', '_buildStep(context, 1,');
  content = content.replaceAll('_buildStep(2,', '_buildStep(context, 2,');
  content = content.replaceAll('_buildStep(3,', '_buildStep(context, 3,');
  
  file.writeAsStringSync(content);
}
