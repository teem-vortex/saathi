import 'call_page.dart';
import 'app_theme.dart';
import 'launcher_options.dart';
import 'elder_launcher.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'elder_overview.dart';
import 'launcher_apps.dart';
import 'guardian_demo.dart';
import 'voice_draft.dart';
import 'connections.dart';
import 'push_notifications.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: key);
    await initializePush();
    if (Supabase.instance.client.auth.currentUser != null) {
      try {
        await registerPush();
      } catch (_) {
        /* Available again on sign-in. */
      }
    }
  }
  final preferences = await SharedPreferences.getInstance();
  runApp(SaathiApp(preferences: preferences));
}

const translations = <String, List<String>>{
  'English': [
    'How will you use Saathi?',
    'Elder mode',
    'Guardian mode',
    'A simple space to connect with family',
    'See updates and stay connected',
    'Settings',
    'Language',
    'Switch mode',
    'Hello!',
    'Swipe sideways for more actions',
    'Talk to Saathi',
    'Hear messages',
    'I’m okay',
    'Ask for a call',
    'This action is coming soon.',
    'Guardian dashboard',
    'Stay connected',
    'Updates from your family will appear here.',
    'Your family',
    'No family members connected yet.',
    'Recent updates',
    'No updates yet. Check-ins and requests will appear here.',
    'Preview • Actions will be available later.',
    'Preview • Family connection and messaging will be available later.',
  ],
  'தமிழ்': [
    'சாதியை எவ்வாறு பயன்படுத்துவீர்கள்?',
    'மூத்தோர் பகுதி',
    'பராமரிப்பாளர் பகுதி',
    'குடும்பத்துடன் இணைந்திருக்க',
    'செய்திகளைப் பார்த்து தொடர்பில் இருங்கள்',
    'அமைப்புகள்',
    'மொழி',
    'பகுதியை மாற்று',
    'வணக்கம்!',
    'மேலும் பார்க்க பக்கவாட்டில் நகர்த்தவும்',
    'சாதியிடம் பேசுங்கள்',
    'செய்திகளைக் கேளுங்கள்',
    'நான் நலமாக இருக்கிறேன்',
    'அழைக்கச் சொல்லுங்கள்',
    'இந்த வசதி விரைவில் வரும்.',
    'பராமரிப்பாளர் முகப்பு',
    'தொடர்பில் இருங்கள்',
    'குடும்பத்தின் புதுப்பிப்புகள் இங்கே தோன்றும்.',
    'உங்கள் குடும்பம்',
    'இன்னும் குடும்ப உறுப்பினர்கள் இணைக்கப்படவில்லை.',
    'சமீபத்திய செய்திகள்',
    'இன்னும் செய்திகள் இல்லை. நலம் விசாரிப்புகள் இங்கே தோன்றும்.',
    'முன்னோட்டம் • வசதிகள் பின்னர் கிடைக்கும்.',
    'முன்னோட்டம் • குடும்ப இணைப்பு பின்னர் கிடைக்கும்.',
  ],
  'ಕನ್ನಡ': [
    'ಸಾಥಿಯನ್ನು ಹೇಗೆ ಬಳಸುತ್ತೀರಿ?',
    'ಹಿರಿಯರ ವಿಭಾಗ',
    'ಪಾಲಕರ ವಿಭಾಗ',
    'ಕುಟುಂಬದೊಂದಿಗೆ ಸಂಪರ್ಕದಲ್ಲಿರಲು',
    'ಮಾಹಿತಿ ನೋಡಿ ಸಂಪರ್ಕದಲ್ಲಿರಿ',
    'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
    'ಭಾಷೆ',
    'ವಿಭಾಗ ಬದಲಿಸಿ',
    'ನಮಸ್ಕಾರ!',
    'ಹೆಚ್ಚಿನ ಆಯ್ಕೆಗಳಿಗೆ ಪಕ್ಕಕ್ಕೆ ಸರಿಸಿ',
    'ಸಾಥಿಯೊಂದಿಗೆ ಮಾತನಾಡಿ',
    'ಸಂದೇಶಗಳನ್ನು ಕೇಳಿ',
    'ನಾನು ಚೆನ್ನಾಗಿದ್ದೇನೆ',
    'ಕರೆ ಮಾಡಲು ತಿಳಿಸಿ',
    'ಈ ಸೌಲಭ್ಯ ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿದೆ.',
    'ಪಾಲಕರ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
    'ಸಂಪರ್ಕದಲ್ಲಿರಿ',
    'ಕುಟುಂಬದ ಮಾಹಿತಿ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತದೆ.',
    'ನಿಮ್ಮ ಕುಟುಂಬ',
    'ಇನ್ನೂ ಕುಟುಂಬದ ಸದಸ್ಯರು ಸಂಪರ್ಕಿಸಿಲ್ಲ.',
    'ಇತ್ತೀಚಿನ ಮಾಹಿತಿ',
    'ಇನ್ನೂ ಮಾಹಿತಿ ಇಲ್ಲ. ಸಂದೇಶಗಳು ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ.',
    'ಮುನ್ನೋಟ • ಸೌಲಭ್ಯಗಳು ನಂತರ ಲಭ್ಯ.',
    'ಮುನ್ನೋಟ • ಕುಟುಂಬ ಸಂಪರ್ಕ ನಂತರ ಲಭ್ಯ.',
  ],
  'తెలుగు': [
    'సాథిని ఎలా ఉపయోగిస్తారు?',
    'పెద్దల విభాగం',
    'సంరక్షకుల విభాగం',
    'కుటుంబంతో అనుసంధానంగా ఉండటానికి',
    'సమాచారం చూసి సంబంధంలో ఉండండి',
    'సెట్టింగ్‌లు',
    'భాష',
    'విభాగం మార్చండి',
    'నమస్కారం!',
    'మరిన్ని చూడటానికి పక్కకు జరపండి',
    'సాథితో మాట్లాడండి',
    'సందేశాలు వినండి',
    'నేను బాగున్నాను',
    'కాల్ చేయమని అడగండి',
    'ఈ సౌకర్యం త్వరలో వస్తుంది.',
    'సంరక్షకుల డాష్‌బోర్డ్',
    'సంబంధంలో ఉండండి',
    'కుటుంబ సమాచారం ఇక్కడ కనిపిస్తుంది.',
    'మీ కుటుంబం',
    'కుటుంబ సభ్యులు ఇంకా కనెక్ట్ కాలేదు.',
    'ఇటీవలి సమాచారం',
    'ఇంకా సమాచారం లేదు. సందేశాలు ఇక్కడ కనిపిస్తాయి.',
    'ప్రివ్యూ • సౌకర్యాలు తర్వాత అందుబాటులో ఉంటాయి.',
    'ప్రివ్యూ • కుటుంబ కనెక్షన్ తర్వాత అందుబాటులో ఉంటుంది.',
  ],
  'മലയാളം': [
    'സാഥി എങ്ങനെ ഉപയോഗിക്കും?',
    'മുതിർന്നവരുടെ വിഭാഗം',
    'പരിചാരകരുടെ വിഭാഗം',
    'കുടുംബവുമായി ബന്ധപ്പെടാൻ',
    'വിവരങ്ങൾ കണ്ട് ബന്ധം നിലനിർത്തുക',
    'ക്രമീകരണങ്ങൾ',
    'ഭാഷ',
    'വിഭാഗം മാറ്റുക',
    'നമസ്കാരം!',
    'കൂടുതൽ കാണാൻ വശത്തേക്ക് നീക്കുക',
    'സാഥിയോട് സംസാരിക്കുക',
    'സന്ദേശങ്ങൾ കേൾക്കുക',
    'എനിക്ക് സുഖമാണ്',
    'വിളിക്കാൻ പറയുക',
    'ഈ സൗകര്യം ഉടൻ വരും.',
    'പരിചാരക ഡാഷ്‌ബോർഡ്',
    'ബന്ധം നിലനിർത്താം',
    'കുടുംബത്തിന്റെ വിവരങ്ങൾ ഇവിടെ കാണാം.',
    'നിങ്ങളുടെ കുടുംബം',
    'കുടുംബാംഗങ്ങളെ ഇതുവരെ ചേർത്തിട്ടില്ല.',
    'പുതിയ വിവരങ്ങൾ',
    'ഇതുവരെ വിവരങ്ങളില്ല. സന്ദേശങ്ങൾ ഇവിടെ കാണാം.',
    'പ്രിവ്യൂ • സൗകര്യങ്ങൾ പിന്നീട് ലഭ്യമാകും.',
    'പ്രിവ്യൂ • കുടുംബ ബന്ധം പിന്നീട് ലഭ്യമാകും.',
  ],
};

class SaathiApp extends StatefulWidget {
  const SaathiApp({super.key, this.preferences});
  final SharedPreferences? preferences;
  @override
  State<SaathiApp> createState() => _SaathiAppState();
}

class _SaathiAppState extends State<SaathiApp> with WidgetsBindingObserver {
  late final ThemeController themeController = ThemeController(
    widget.preferences,
  );
  final navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb || widget.preferences == null) return;
    androidControls.setMethodCallHandler((call) async {
      if (call.method == 'openAlerts') openAlerts();
      if (call.method == 'returnHome') {
        navigator.currentState?.popUntil((route) => route.isFirst);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await androidControls.invokeMethod<bool>('consumeAlert') == true) {
        openAlerts();
      }
      if (!mounted ||
          widget.preferences!.getBool('notificationSetupShown') == true) {
        return;
      }
      await widget.preferences!.setBool('notificationSetupShown', true);
      await androidControls.invokeMethod<void>('requestNotifications');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) themeController.refresh();
  }

  void openAlerts() {
    navigator.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const DemoAlerts()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    themeController.dispose();
    if (!kIsWeb && widget.preferences != null) {
      androidControls.setMethodCallHandler(null);
    }
    super.dispose();
  }

  late String language =
      translations.containsKey(widget.preferences?.getString('language'))
      ? widget.preferences!.getString('language')!
      : 'English';

  @override
  Widget build(BuildContext context) {
    final text = translations[language]!;
    final platformRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final isLauncher = platformRoute == '/elderHome';
    return ThemeScope(
      controller: themeController,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) => MaterialApp(
          title: 'Saathi',
          navigatorKey: navigator,
          debugShowCheckedModeBanner: false,
          theme: saathiTheme(Brightness.light),
          darkTheme: saathiTheme(Brightness.dark),
          themeMode: themeController.mode,
          initialRoute: isLauncher ? '/' : platformRoute,
          onGenerateRoute: (settings) {
            if (settings.name == '/assistant') {
              return MaterialPageRoute<void>(
                builder: (_) => const AssistantPage(),
              );
            }
            return null;
          },
          home: isLauncher
              ? ElderLauncher(
                  preferences: widget.preferences,
                  labelsFor: (language) => translations[language]!,
                  openSettings: (context, language, onChanged) =>
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SettingsPage(
                            language: language,
                            showHomeSettings: true,
                            elder: true,
                            onChanged: onChanged,
                          ),
                        ),
                      ),
                  openAction: openElderAction,
                )
              : Builder(
                  builder: (context) {
                    void openSettings() => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsPage(
                          language: language,
                          onChanged: (value) async {
                            setState(() => language = value);
                            await widget.preferences?.setString(
                              'language',
                              value,
                            );
                          },
                        ),
                      ),
                    );
                    return ModePicker(
                      text: text,
                      openSettings: openSettings,
                      language: language,
                      onChanged: (value) async {
                        setState(() => language = value);
                        await widget.preferences?.setString('language', value);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class ModePicker extends StatelessWidget {
  const ModePicker({
    super.key,
    required this.text,
    required this.openSettings,
    required this.language,
    required this.onChanged,
  });
  final List<String> text;
  final VoidCallback openSettings;
  final String language;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xff246b60),
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                'Saathi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 40),
              Text(text[0], style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              for (var i = 1; i <= 2; i++)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: Icon(
                      i == 1
                          ? Icons.waving_hand_outlined
                          : Icons.people_outline,
                      size: 34,
                    ),
                    title: Text(
                      text[i],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(text[i + 2]),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ModePage(
                          elder: i == 1,
                          language: language,
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ModePage extends StatefulWidget {
  const ModePage({
    super.key,
    required this.elder,
    required this.language,
    required this.onChanged,
  });
  final bool elder;
  final String language;
  final ValueChanged<String> onChanged;
  @override
  State<ModePage> createState() => _ModePageState();
}

class _ModePageState extends State<ModePage> {
  late String language = widget.language;

  @override
  Widget build(BuildContext context) {
    final t = translations[language]!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.elder ? 'Saathi' : t[15]),
        actions: [
          IconButton(
            tooltip: t[5],
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(
                  language: language,
                  showHomeSettings: widget.elder,
                  elder: widget.elder,
                  onChanged: (value) {
                    setState(() => language = value);
                    widget.onChanged(value);
                  },
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t[7]),
          ),
        ],
      ),
      body: widget.elder
          ? LayoutBuilder(
              builder: (context, constraints) => ListView(
                children: [
                  ElderOverview(language: language),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: (constraints.maxWidth - 54) / 2,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) => Card(
                      color: Theme.of(context).cardTheme.color,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          if (index == 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    VoiceDraftPage(language: language),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(t[14])));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                [
                                  Icons.mic_none,
                                  Icons.volume_up_outlined,
                                  Icons.favorite_border,
                                  Icons.phone_outlined,
                                ][index],
                                size: 42,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Flexible(
                                child: Text(
                                  index == 4
                                      ? (callLabels[language] ??
                                            callLabels['English']!)[0]
                                      : t[10 + index],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(t[22]),
                  ),
                ],
              ),
            )
          : const GuardianDemo(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.language,
    required this.onChanged,
    this.showHomeSettings = false,
    this.elder,
  });
  final bool? elder;
  final String language;
  final ValueChanged<String> onChanged;
  final bool showHomeSettings;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  late String language = widget.language;
  bool isHome = false;
  bool highlightHome = false;
  final homeKey = GlobalKey();
  bool isAssistant = false;
  bool callEnabled = true;

  Future<void> loadCallSetting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if (mounted) {
      setState(() => callEnabled = prefs.getBool(callEnabledKey) ?? true);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.showHomeSettings) {
      refreshHome();
      loadCallSetting();
    }
  }

  Future<void> refreshHome() async {
    try {
      final value =
          await androidControls.invokeMethod<bool>('homeStatus') ?? false;
      final assistant =
          await androidControls.invokeMethod<bool>('assistantStatus') ?? false;
      if (mounted) {
        setState(() {
          isHome = value;
          isAssistant = assistant;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isHome = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.showHomeSettings) {
      refreshHome();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = translations[language]!;
    return Scaffold(
      appBar: AppBar(title: Text(t[5])),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<String>(
              key: ValueKey(language),
              initialValue: language,
              decoration: InputDecoration(
                labelText: t[6],
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final option in translations.keys)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (option) {
                if (option == null) return;
                setState(() => language = option);
                widget.onChanged(option);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DropdownButtonFormField<ThemeMode>(
              key: ValueKey(ThemeScope.of(context).mode),
              initialValue: ThemeScope.of(context).mode,
              decoration: InputDecoration(
                labelText:
                    (themeLabels[language] ?? themeLabels['English']!)[0],
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final entry in [
                  (ThemeMode.system, 1),
                  (ThemeMode.dark, 2),
                  (ThemeMode.light, 3),
                ])
                  DropdownMenuItem(
                    value: entry.$1,
                    child: Text(
                      (themeLabels[language] ??
                          themeLabels['English']!)[entry.$2],
                    ),
                  ),
              ],
              onChanged: (mode) {
                if (mode != null) ThemeScope.of(context).setMode(mode);
              },
            ),
          ),
          if (widget.elder != null)
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Saathi connections'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ConnectionsPage(elder: widget.elder!),
                ),
              ),
            ),
          if (widget.showHomeSettings) ...[
            SwitchListTile(
              title: Text((callLabels[language] ?? callLabels['English']!)[0]),
              subtitle: Text(
                (callLabels[language] ?? callLabels['English']!)[7],
              ),
              value: callEnabled,
              onChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(callEnabledKey, value);
                if (mounted) setState(() => callEnabled = value);
              },
            ),
            LauncherSettings(
              enabled: isHome,
              onDisabledTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Choose Use Saathi as Home to enable launcher settings.',
                    ),
                  ),
                );
                setState(() => highlightHome = true);
                final target = homeKey.currentContext;
                if (target != null) {
                  Scrollable.ensureVisible(
                    target,
                    alignment: 0.5,
                    duration: const Duration(milliseconds: 350),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_none),
              title: Text(
                isAssistant
                    ? 'Change phone assistant'
                    : 'Use Saathi as phone assistant',
              ),
              subtitle: Text(
                isAssistant
                    ? 'Saathi is your phone assistant'
                    : 'Choose Saathi in Android default apps',
              ),
              onTap: () async {
                final opened =
                    await androidControls.invokeMethod<bool>(
                      'assistantSettings',
                    ) ??
                    false;
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Open Android Settings and choose Default apps, then Digital assistant app.',
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              key: homeKey,
              tileColor: highlightHome && !isHome
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              leading: const Icon(Icons.home_outlined),
              title: Text(launcherLabels[language]![6]),
              subtitle: Text(
                isHome
                    ? launcherLabels[language]![8]
                    : launcherLabels[language]![9],
              ),
              onTap: () async {
                await androidControls.invokeMethod<bool>('requestHome');
                await refreshHome();
                if (mounted && isHome) setState(() => highlightHome = false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(launcherLabels[language]![7]),
              enabled: true,
              textColor: isHome ? null : Theme.of(context).disabledColor,
              iconColor: isHome ? null : Theme.of(context).disabledColor,
              onTap: isHome
                  ? () => androidControls.invokeMethod<void>('homeSettings')
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Choose Use Saathi as Home to enable launcher settings.',
                          ),
                        ),
                      );
                      setState(() => highlightHome = true);
                      final target = homeKey.currentContext;
                      if (target != null) {
                        Scrollable.ensureVisible(
                          target,
                          alignment: 0.5,
                          duration: const Duration(milliseconds: 350),
                        );
                      }
                    },
            ),
          ],
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notification settings'),
              onTap: () =>
                  androidControls.invokeMethod<void>('notificationSettings'),
            ),
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.battery_saver_outlined),
              title: const Text('Battery optimization'),
              onTap: () =>
                  androidControls.invokeMethod<void>('batterySettings'),
            ),
        ],
      ),
    );
  }
}

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Talk to Saathi')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_off_outlined, size: 80),
            const SizedBox(height: 20),
            Text(
              'Voice assistant is not connected yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Voice conversations will be available after setup.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  SystemNavigator.pop();
                }
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );
}

void openElderAction(BuildContext context, int index, String previewLabel) {
  if (index == 0) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AssistantPage()),
    );
  } else {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(previewLabel)));
  }
}
