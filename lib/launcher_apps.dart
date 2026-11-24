import 'package:material_ui/material_ui.dart';

import 'guardian_demo.dart' show androidControls;

const launcherLabels = <String, List<String>>{
  'English': [
    'Phone',
    'Messages',
    'Camera',
    'Settings',
    'All apps',
    'App unavailable',
    'Use Saathi as Home',
    'Change Home app',
    'Saathi is your Home app',
    'Choose Saathi as your Home app',
  ],
  'தமிழ்': [
    'தொலைபேசி',
    'செய்திகள்',
    'கேமரா',
    'அமைப்புகள்',
    'அனைத்து செயலிகள்',
    'செயலி கிடைக்கவில்லை',
    'சாதியை முகப்பாகப் பயன்படுத்து',
    'முகப்பை மாற்று',
    'சாதி உங்கள் முகப்பு',
    'சாதியை முகப்பாகத் தேர்ந்தெடு',
  ],
  'ಕನ್ನಡ': [
    'ಫೋನ್',
    'ಸಂದೇಶಗಳು',
    'ಕ್ಯಾಮೆರಾ',
    'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
    'ಎಲ್ಲಾ ಆ್ಯಪ್‌ಗಳು',
    'ಆ್ಯಪ್ ಲಭ್ಯವಿಲ್ಲ',
    'ಸಾಥಿಯನ್ನು ಮುಖಪುಟವಾಗಿಸಿ',
    'ಮುಖಪುಟ ಬದಲಿಸಿ',
    'ಸಾಥಿ ನಿಮ್ಮ ಮುಖಪುಟ',
    'ಸಾಥಿಯನ್ನು ಮುಖಪುಟವಾಗಿ ಆಯ್ಕೆಮಾಡಿ',
  ],
  'తెలుగు': [
    'ఫోన్',
    'సందేశాలు',
    'కెమెరా',
    'సెట్టింగ్‌లు',
    'అన్ని యాప్‌లు',
    'యాప్ అందుబాటులో లేదు',
    'సాథిని హోమ్‌గా వాడండి',
    'హోమ్ యాప్ మార్చండి',
    'సాథి మీ హోమ్ యాప్',
    'సాథిని హోమ్‌గా ఎంచుకోండి',
  ],
  'മലയാളം': [
    'ഫോൺ',
    'സന്ദേശങ്ങൾ',
    'ക്യാമറ',
    'ക്രമീകരണങ്ങൾ',
    'എല്ലാ ആപ്പുകളും',
    'ആപ്പ് ലഭ്യമല്ല',
    'സാഥി ഹോം ആക്കുക',
    'ഹോം ആപ്പ് മാറ്റുക',
    'സാഥി നിങ്ങളുടെ ഹോം ആപ്പാണ്',
    'സാഥിയെ ഹോം ആപ്പായി തിരഞ്ഞെടുക്കുക',
  ],
};

class LauncherAppsGrid extends StatelessWidget {
  const LauncherAppsGrid({super.key, required this.language});
  final String language;

  @override
  Widget build(BuildContext context) {
    final labels = launcherLabels[language] ?? launcherLabels['English']!;
    final actions = ['phone', 'messages', 'camera', 'settings', 'apps'];
    final icons = [
      Icons.phone_outlined,
      Icons.message_outlined,
      Icons.camera_alt_outlined,
      Icons.settings_outlined,
      Icons.apps,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) => Card(
          child: InkWell(
            onTap: () async {
              if (actions[index] == 'apps') {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        InstalledApps(title: labels[4], unavailable: labels[5]),
                  ),
                );
                return;
              }
              bool opened = false;
              try {
                opened =
                    await androidControls.invokeMethod<bool>(
                      'shortcut',
                      actions[index],
                    ) ??
                    false;
              } catch (_) {}
              if (context.mounted && !opened) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(labels[5])));
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icons[index],
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InstalledApps extends StatefulWidget {
  const InstalledApps({
    super.key,
    required this.title,
    required this.unavailable,
  });
  final String title;
  final String unavailable;
  @override
  State<InstalledApps> createState() => _InstalledAppsState();
}

class _InstalledAppsState extends State<InstalledApps>
    with WidgetsBindingObserver {
  late Future<List<dynamic>?> apps;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    apps = androidControls.invokeListMethod<dynamic>('apps');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => apps = androidControls.invokeListMethod<dynamic>('apps'));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<List<dynamic>?>(
      future: apps,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text(widget.unavailable));
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final app = Map<String, dynamic>.from(snapshot.data![index] as Map);
            return ListTile(
              leading: const Icon(Icons.apps),
              title: Text(app['label'] as String),
              onTap: () async {
                bool opened = false;
                try {
                  opened =
                      await androidControls.invokeMethod<bool>(
                        'launchApp',
                        app,
                      ) ??
                      false;
                } catch (_) {}
                if (context.mounted && !opened) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(widget.unavailable)));
                }
              },
            );
          },
        );
      },
    ),
  );
}
