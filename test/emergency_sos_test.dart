import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathi/emergency_sos.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SOS requires a hold and countdown can be cancelled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var alerts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SosButton(
            language: 'English',
            onTriggered: () =>
                Navigator.of(tester.element(find.byType(SosButton))).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SosCountdown(
                      language: 'English',
                      sendAlert: () async {
                        alerts++;
                        return true;
                      },
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
    final shortPress = await tester.startGesture(
      tester.getCenter(find.byType(SosButton)),
    );
    await tester.pump(const Duration(seconds: 2));
    await shortPress.up();
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsNothing);
    final hold = await tester.startGesture(
      tester.getCenter(find.byType(SosButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await hold.up();
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    expect(alerts, 0);
  });
}
