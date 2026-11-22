import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathi/main.dart';

void main() {
  testWidgets('Both modes open and return to the picker', (tester) async {
    await tester.pumpWidget(const SaathiApp());
    await tester.tap(find.text('Elder mode'));
    await tester.pumpAndSettle();
    expect(find.text('Ask for a call'), findsOneWidget);
    await tester.tap(find.text('Switch mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardian mode'));
    await tester.pumpAndSettle();
    expect(find.text('Recent updates'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
