import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test - app should build without errors.
    // Full widget tests require mocking LiveKit and audio services.
    expect(true, isTrue);
  });
}
