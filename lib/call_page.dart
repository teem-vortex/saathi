import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'guardian_demo.dart' show androidControls;

const callEnabledKey = 'elderCallEnabled';
const callContactsKey = 'elderCallContacts';

const callLabels = <String, List<String>>{
  'English': [
    'Call',
    'Add contact',
    'Remove contact',
    'No contacts yet. Use the menu to add one.',
    'Cancel',
    'Confirm call',
    'Unable to place call',
    'User extras',
    'Remove',
    'Contact already added',
  ],
  'தமிழ்': [
    'அழைப்பு',
    'தொடர்பைச் சேர்',
    'தொடர்பை அகற்று',
    'தொடர்பைச் சேர்க்க மெனுவைப் பயன்படுத்தவும்.',
    'ரத்து',
    'அழைப்பை உறுதிசெய்',
    'அழைக்க முடியவில்லை',
    'கூடுதல் வசதிகள்',
    'அகற்று',
    'தொடர்பு ஏற்கனவே உள்ளது',
  ],
  'ಕನ್ನಡ': [
    'ಕರೆ',
    'ಸಂಪರ್ಕ ಸೇರಿಸಿ',
    'ಸಂಪರ್ಕ ತೆಗೆದುಹಾಕಿ',
    'ಸಂಪರ್ಕ ಸೇರಿಸಲು ಮೆನು ಬಳಸಿ.',
    'ರದ್ದು',
    'ಕರೆಯನ್ನು ದೃಢೀಕರಿಸಿ',
    'ಕರೆ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ',
    'ಹೆಚ್ಚುವರಿ ಆಯ್ಕೆಗಳು',
    'ತೆಗೆದುಹಾಕಿ',
    'ಸಂಪರ್ಕ ಈಗಾಗಲೇ ಸೇರಿಸಲಾಗಿದೆ',
  ],
  'తెలుగు': [
    'కాల్',
    'పరిచయాన్ని జోడించు',
    'పరిచయాన్ని తొలగించు',
    'పరిచయాన్ని జోడించడానికి మెనుని ఉపయోగించండి.',
    'రద్దు',
    'కాల్ నిర్ధారించండి',
    'కాల్ చేయలేకపోయాము',
    'అదనపు ఎంపికలు',
    'తొలగించు',
    'పరిచయం ఇప్పటికే జోడించబడింది',
  ],
  'മലയാളം': [
    'വിളിക്കുക',
    'കോൺടാക്റ്റ് ചേർക്കുക',
    'കോൺടാക്റ്റ് നീക്കുക',
    'കോൺടാക്റ്റ് ചേർക്കാൻ മെനു ഉപയോഗിക്കുക.',
    'റദ്ദാക്കുക',
    'വിളി സ്ഥിരീകരിക്കുക',
    'വിളിക്കാൻ കഴിഞ്ഞില്ല',
    'അധിക സൗകര്യങ്ങൾ',
    'നീക്കുക',
    'കോൺടാക്റ്റ് ഇതിനകം ചേർത്തിട്ടുണ്ട്',
  ],
};

class CallPage extends StatefulWidget {
  const CallPage({super.key, required this.language});
  final String language;
  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  List<Map<String, String>> contacts = [];
  bool removing = false;
  late final Future<void> initialLoad = load();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final saved = prefs.getStringList(callContactsKey) ?? [];
    final parsed = <Map<String, String>>[];
    for (final item in saved) {
      try {
        final entry = jsonDecode(item);
        if (entry is Map &&
            entry['name'] is String &&
            entry['number'] is String) {
          parsed.add({
            'name': entry['name'] as String,
            'number': entry['number'] as String,
          });
        }
      } catch (_) {}
    }
    if (mounted) setState(() => contacts = parsed);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      callContactsKey,
      contacts.map(jsonEncode).toList(),
    );
  }

  Future<void> add() async {
    try {
      final result = await androidControls.invokeMapMethod<String, dynamic>(
        'pickCallContact',
      );
      if (result == null || !mounted) return;
      final name = result['name'];
      final number = result['number'];
      if (name is! String || number is! String || number.trim().isEmpty) return;
      await load();
      if (!mounted) return;
      if (contacts.any(
        (entry) =>
            entry['number']!.replaceAll(RegExp(r'[\s()-]'), '') ==
            number.replaceAll(RegExp(r'[\s()-]'), ''),
      )) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(labels[9])));
        return;
      }
      setState(() => contacts.add({'name': name, 'number': number}));
      await save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(labels[6])));
      }
    }
  }

  List<String> get labels =>
      callLabels[widget.language] ?? callLabels['English']!;

  Future<void> selectContact(Map<String, String> contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(removing ? labels[2] : labels[5]),
        content: Text('${contact['name']}\n${contact['number']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(labels[4]),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(removing ? labels[8] : labels[0]),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (removing) {
      setState(() => contacts.remove(contact));
      await save();
      return;
    }
    try {
      final success =
          await androidControls.invokeMethod<bool>(
            'placeCall',
            contact['number'],
          ) ??
          false;
      if (!success && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(labels[6])));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(labels[6])));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(labels[0]),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'add') {
              add();
            } else {
              setState(() => removing = !removing);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'add', child: Text(labels[1])),
            PopupMenuItem(value: 'remove', child: Text(labels[2])),
          ],
        ),
      ],
    ),
    body: FutureBuilder<void>(
      future: initialLoad,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (contacts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(labels[3], textAlign: TextAlign.center),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 170,
          ),
          itemCount: contacts.length,
          itemBuilder: (context, index) => Card(
            child: InkWell(
              onTap: () => selectContact(contacts[index]),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      removing
                          ? Icons.remove_circle_outline
                          : Icons.phone_outlined,
                      size: 38,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contacts[index]['name']!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
