import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('shows the frontend connection card', (WidgetTester tester) async {
    await tester.pumpWidget(const FrontendApp());

    expect(find.text('Frontend conectado'), findsOneWidget);
    expect(find.text('Probar conexión'), findsOneWidget);
  });
}
