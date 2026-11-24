import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeLabels = <String, List<String>>{
  'English': ['Theme', 'Use system theme', 'Dark', 'Light'],
  'தமிழ்': ['தோற்றம்', 'கணினி தோற்றத்தைப் பயன்படுத்து', 'இருள்', 'ஒளி'],
  'ಕನ್ನಡ': ['ಥೀಮ್', 'ಸಿಸ್ಟಮ್ ಥೀಮ್ ಬಳಸಿ', 'ಡಾರ್ಕ್', 'ಲೈಟ್'],
  'తెలుగు': ['థీమ్', 'సిస్టమ్ థీమ్ ఉపయోగించండి', 'డార్క్', 'లైట్'],
  'മലയാളം': ['തീം', 'സിസ്റ്റം തീം ഉപയോഗിക്കുക', 'ഡാർക്ക്', 'ലൈറ്റ്'],
};

class ThemeController extends ChangeNotifier {
  ThemeController(this.preferences)
    : mode = parse(preferences?.getString('themeMode'));

  final SharedPreferences? preferences;
  ThemeMode mode;
  static ThemeMode parse(String? value) =>
      ThemeMode.values.where((mode) => mode.name == value).firstOrNull ??
      ThemeMode.system;

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    notifyListeners();
    await preferences?.setString('themeMode', value.name);
  }

  Future<void> refresh() async {
    await preferences?.reload();
    final updated = parse(preferences?.getString('themeMode'));
    if (updated != mode) {
      mode = updated;
      notifyListeners();
    }
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}

ThemeData saathiTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff246b60),
    brightness: brightness,
    surface: dark ? const Color(0xff141d1b) : const Color(0xfff7f6f0),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      color: dark ? const Color(0xff25332f) : Colors.white,
    ),
  );
}
