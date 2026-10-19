import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studdy/main.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets('Studdy app displays its branded startup screen', (tester) async {
    await tester.pumpWidget(const StuddyApp());

    expect(find.text('Studdy'), findsOneWidget);
    expect(find.text('your study buddy'), findsOneWidget);
  });
}
