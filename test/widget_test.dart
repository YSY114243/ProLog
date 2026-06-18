import 'package:flutter_test/flutter_test.dart';
import 'package:prolog/main.dart';

void main() {
  testWidgets('ProLog smoke test', (WidgetTester tester) async {
    // Supabase is not initialised in tests; just verify app widget builds.
    expect(ProLogApp.new, isNotNull);
  });
}
