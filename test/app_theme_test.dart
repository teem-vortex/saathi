import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathi/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme defaults to system and persists changes', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(preferences);
    expect(controller.mode, ThemeMode.system);

    await controller.setMode(ThemeMode.dark);
    expect(ThemeController(preferences).mode, ThemeMode.dark);

    await preferences.setString('themeMode', 'light');
    await controller.refresh();
    expect(controller.mode, ThemeMode.light);

    await preferences.setString('themeMode', 'unknown');
    await controller.refresh();
    expect(controller.mode, ThemeMode.system);
    controller.dispose();
  });
}
