import re

file_path = r'C:\Projects\Professional Log\lib\screens\landing_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix _buildFeatureCard
content = content.replace('Widget _buildFeatureCard(_FeatureData f)', 'Widget _buildFeatureCard(BuildContext context, _FeatureData f)')

# Fix _buildStep
content = content.replace('Widget _buildStep(int stepNumber, IconData icon, String title, String description)', 'Widget _buildStep(BuildContext context, int stepNumber, IconData icon, String title, String description)')
content = content.replace('_buildStep(1,', '_buildStep(context, 1,')
content = content.replace('_buildStep(2,', '_buildStep(context, 2,')
content = content.replace('_buildStep(3,', '_buildStep(context, 3,')

# Fix any context-less Theme.of calls inside landing_screen
# Wait, let's just make sure _buildCopy takes context
content = content.replace('Widget _buildCopy({required TextAlign textAlign})', 'Widget _buildCopy(BuildContext context, {required TextAlign textAlign})')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
