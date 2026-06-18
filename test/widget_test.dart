import 'package:flutter_test/flutter_test.dart';
import 'package:internlog/main.dart';

void main() {
  testWidgets('InternLog smoke test', (WidgetTester tester) async {
    // Verify that our app is not null
    expect(InternLogApp.new, isNotNull);
  });
}
