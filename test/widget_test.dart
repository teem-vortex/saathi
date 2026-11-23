import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:saathi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    expect(find.text('Health overview'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Voice draft transcribes and reads back without sending', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('saathi/android');
    final calls = <MethodCall>[];
    var listens = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'listen') {
            listens++;
            return listens == 1
                ? 'Hello family, how are you?'
                : 'send it to the guardian';
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(const SaathiApp());
    await tester.tap(find.text('Elder mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Talk to Saathi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speak message'));
    await tester.pumpAndSettle();
    expect(find.text('Hello family, how are you?'), findsOneWidget);
    await tester.tap(find.text('Read draft aloud'));
    await tester.pumpAndSettle();
    expect(
      calls.where((call) => call.method == 'speak').single.arguments['text'],
      'Hello family, how are you?',
    );
    await tester.tap(find.text('Speak message'));
    await tester.pumpAndSettle();
    expect(find.text('Hello family, how are you?'), findsOneWidget);
    expect(find.textContaining('Your message has not been sent'), findsOneWidget);
    expect(calls.where((call) => call.method == 'composeSms'), isEmpty);
  });
}
