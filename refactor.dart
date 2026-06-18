import 'dart:io';

void main() {
  final logFile = File('analyze.log');
  if (!logFile.existsSync()) return;
  final logLines = logFile.readAsLinesSync();

  final Map<String, List<int>> invalidConstLines = {};
  
  for (final line in logLines) {
    if (line.contains('const_eval_method_invocation') || line.contains('invalid_constant') || line.contains('non_constant_list_element')) {
      final parts = line.split(' - ');
      if (parts.length >= 3) {
        final locationInfo = parts[2].trim();
        final locParts = locationInfo.split(':');
        if (locParts.length >= 2) {
          final filePath = locParts[0];
          final lineNum = int.tryParse(locParts[1]);
          if (lineNum != null) {
            invalidConstLines.putIfAbsent(filePath, () => []).add(lineNum);
          }
        }
      }
    }
  }

  // Strip 'const ' from invalid lines (searching up to 10 lines backwards)
  for (final entry in invalidConstLines.entries) {
    final file = File(entry.key);
    if (!file.existsSync()) continue;
    
    final lines = file.readAsLinesSync();
    for (final lineNum in entry.value) {
      int targetLine = lineNum - 1;
      
      // Search upwards for 'const '
      for (int i = 0; i < 10; i++) {
        int idx = targetLine - i;
        if (idx >= 0 && idx < lines.length) {
          if (lines[idx].contains('const ')) {
            lines[idx] = lines[idx].replaceFirst(RegExp(r'\bconst\s+'), '');
            break; // only strip the nearest const
          }
        }
      }
    }
    file.writeAsStringSync(lines.join('\n'));
  }
}
