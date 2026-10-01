import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hospital_queue_flutter/main.dart';
import 'package:smart_hospital_queue_flutter/data/local/mock_auth_repository_impl.dart';
import 'package:smart_hospital_queue_flutter/providers/repository_providers.dart';

void main() {
  testWidgets('App smoke test loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: SmartHospitalApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SmartHospitalApp), findsOneWidget);
  });
}
