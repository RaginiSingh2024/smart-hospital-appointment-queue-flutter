import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hospital_queue_flutter/main.dart';

void main() {
  testWidgets('App smoke test loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartHospitalApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SmartHospitalApp), findsOneWidget);
  });
}
