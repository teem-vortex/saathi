import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'connections.dart';
import 'guardian_demo.dart' show androidControls;

const emergencyNumber = '112';
const sosDemoKey = 'sosDemoMode';

// SOS, hold, cancel, sending, sent, failed, dial instruction, demo, done, dial failed
const sosLabels = <String, List<String>>{
  'English': [
    'SOS',
    'Hold for 3 seconds to alert family',
    'Cancel',
    'Alerting family…',
    'Alert saved for all guardians. Notification requested.',
    'Alert failed or could not be confirmed. Call for help.',
    'Press the green call button to reach emergency services.',
    'SOS demo mode (no emergency dialer)',
    'Done',
    'Could not open the dialer. Call emergency services yourself.',
    'Demo mode still sends real alerts to connected guardians.',
  ],
  'தமிழ்': [
    'SOS',
    'குடும்பத்தை எச்சரிக்க 3 விநாடிகள் அழுத்தவும்',
    'ரத்து',
    'குடும்பத்தை எச்சரிக்கிறது…',
    'அனைத்து பாதுகாவலர்களுக்கும் செய்தி சேமிக்கப்பட்டது. அறிவிப்பு கோரப்பட்டது.',
    'எச்சரிக்கையை உறுதிப்படுத்த முடியவில்லை. உதவிக்கு அழைக்கவும்.',
    'அவசர சேவையை அடைய பச்சை அழைப்பு பொத்தானை அழுத்தவும்.',
    'SOS சோதனை முறை (அவசர அழைப்பு இல்லை)',
    'முடிந்தது',
    'அழைப்புத் திரையைத் திறக்க முடியவில்லை. அவசர சேவையை அழைக்கவும்.',
    'சோதனை முறையிலும் இணைக்கப்பட்ட பாதுகாவலர்களுக்கு உண்மையான எச்சரிக்கை அனுப்பப்படும்.',
  ],
  'ಕನ್ನಡ': [
    'SOS',
    'ಕುಟುಂಬಕ್ಕೆ ತಿಳಿಸಲು 3 ಸೆಕೆಂಡು ಒತ್ತಿ ಹಿಡಿಯಿರಿ',
    'ರದ್ದು',
    'ಕುಟುಂಬಕ್ಕೆ ತಿಳಿಸಲಾಗುತ್ತಿದೆ…',
    'ಎಲ್ಲ ರಕ್ಷಕರಿಗೆ ಸಂದೇಶ ಉಳಿಸಲಾಗಿದೆ. ಅಧಿಸೂಚನೆ ಕೋರಲಾಗಿದೆ.',
    'ಎಚ್ಚರಿಕೆಯನ್ನು ದೃಢಪಡಿಸಲಾಗಿಲ್ಲ. ಸಹಾಯಕ್ಕೆ ಕರೆ ಮಾಡಿ.',
    'ತುರ್ತು ಸೇವೆಗೆ ಹಸಿರು ಕರೆ ಗುಂಡಿ ಒತ್ತಿರಿ.',
    'SOS ಪರೀಕ್ಷಾ ವಿಧಾನ (ತುರ್ತು ಡಯಲರ್ ಇಲ್ಲ)',
    'ಮುಗಿದಿದೆ',
    'ಡಯಲರ್ ತೆರೆಯಲಿಲ್ಲ. ತುರ್ತು ಸೇವೆಗೆ ಕರೆ ಮಾಡಿ.',
    'ಪರೀಕ್ಷಾ ವಿಧಾನದಲ್ಲೂ ಸಂಪರ್ಕಿತ ರಕ್ಷಕರಿಗೆ ನಿಜವಾದ ಎಚ್ಚರಿಕೆ ಕಳುಹಿಸಲಾಗುತ್ತದೆ.',
  ],
  'తెలుగు': [
    'SOS',
    'కుటుంబానికి తెలియజేయడానికి 3 సెకన్లు నొక్కి ఉంచండి',
    'రద్దు',
    'కుటుంబానికి తెలియజేస్తోంది…',
    'అందరు సంరక్షకులకు సందేశం సేవ్ అయింది. నోటిఫికేషన్ కోరబడింది.',
    'హెచ్చరిక నిర్ధారించబడలేదు. సహాయం కోసం కాల్ చేయండి.',
    'అత్యవసర సేవలకు ఆకుపచ్చ కాల్ బటన్ నొక్కండి.',
    'SOS పరీక్ష మోడ్ (అత్యవసర డయలర్ లేదు)',
    'పూర్తయింది',
    'డయలర్ తెరవలేదు. అత్యవసర సేవలకు కాల్ చేయండి.',
    'పరీక్ష మోడ్‌లో కూడా కనెక్ట్ అయిన సంరక్షకులకు నిజమైన హెచ్చరిక పంపబడుతుంది.',
  ],
  'മലയാളം': [
    'SOS',
    'കുടുംബത്തെ അറിയിക്കാൻ 3 സെക്കൻഡ് അമർത്തിപ്പിടിക്കുക',
    'റദ്ദാക്കുക',
    'കുടുംബത്തെ അറിയിക്കുന്നു…',
    'എല്ലാ രക്ഷിതാക്കൾക്കും സന്ദേശം സൂക്ഷിച്ചു. അറിയിപ്പ് അഭ്യർത്ഥിച്ചു.',
    'അറിയിപ്പ് സ്ഥിരീകരിക്കാനായില്ല. സഹായത്തിന് വിളിക്കുക.',
    'അടിയന്തര സേവനത്തിന് പച്ച കോൾ ബട്ടൺ അമർത്തുക.',
    'SOS പരീക്ഷണ രീതി (അടിയന്തര ഡയലർ ഇല്ല)',
    'പൂർത്തിയായി',
    'ഡയലർ തുറന്നില്ല. അടിയന്തര സേവനത്തെ വിളിക്കുക.',
    'പരീക്ഷണ രീതിയിലും ബന്ധിപ്പിച്ച രക്ഷിതാക്കൾക്ക് യഥാർത്ഥ അറിയിപ്പ് അയയ്ക്കും.',
  ],
};

class SosButton extends StatefulWidget {
  const SosButton({super.key, required this.language, this.onTriggered});
  final String language;
  final VoidCallback? onTriggered;
  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            controller.reset();
            if (widget.onTriggered != null) {
              widget.onTriggered!();
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SosCountdown(language: widget.language),
                ),
              );
            }
          }
        });
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = sosLabels[widget.language] ?? sosLabels['English']!;
    return Semantics(
      label: '${labels[0]}. ${labels[1]}',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => controller.forward(),
        onTapUp: (_) => controller.reset(),
        onTapCancel: () => controller.reset(),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xffb00020),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text(
                labels[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                labels[1],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 19),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: controller,
                builder: (_, _) => LinearProgressIndicator(
                  value: controller.value,
                  backgroundColor: Colors.white38,
                  color: Colors.white,
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SosCountdown extends StatefulWidget {
  const SosCountdown({super.key, required this.language, this.sendAlert});
  final String language;
  final Future<bool> Function()? sendAlert;
  @override
  State<SosCountdown> createState() => _SosCountdownState();
}

class _SosCountdownState extends State<SosCountdown> {
  int remaining = 5;
  Timer? timer;
  bool sending = false;
  bool? sent;
  bool demo = true;
  bool dialFailed = false;
  List<String> get labels =>
      sosLabels[widget.language] ?? sosLabels['English']!;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining == 1) {
        t.cancel();
        setState(() {
          remaining = 0;
          sending = true;
        });
        execute();
      } else {
        setState(() => remaining--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> execute() async {
    final prefs = await SharedPreferences.getInstance();
    demo = prefs.getBool(sosDemoKey) ?? true;
    bool success = false;
    try {
      success = await (widget.sendAlert?.call() ?? sendSos());
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() {
      sent = success;
      sending = false;
    });
    if (!demo) {
      try {
        dialFailed =
            !(await androidControls.invokeMethod<bool>('placeCall', {
                  'number': emergencyNumber,
                  'dialOnly': true,
                }) ??
                false);
      } catch (_) {
        dialFailed = true;
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !sending && remaining == 0,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (remaining > 0) ...[
                  Text(
                    '$remaining',
                    style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 100,
                    child: FilledButton(
                      onPressed: () {
                        timer?.cancel();
                        Navigator.pop(context);
                      },
                      child: Text(
                        labels[2],
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ] else if (sending) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    labels[3],
                    style: const TextStyle(fontSize: 26),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    sent == true ? labels[4] : labels[5],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    demo
                        ? labels[7]
                        : dialFailed
                        ? labels[9]
                        : labels[6],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(labels[8]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<bool> sendSos() async {
  if (!messagingConfigured) return false;
  final db = Supabase.instance.client;
  final user = db.auth.currentUser;
  if (user == null) return false;
  Map<Object?, Object?>? location;
  try {
    location = await androidControls
        .invokeMapMethod<Object?, Object?>('sosLocation')
        .timeout(const Duration(seconds: 4));
  } catch (_) {}
  final rawName = user.userMetadata?['name'];
  final name = rawName is String ? rawName.trim() : null;
  final who = name == null || name.isEmpty ? 'An elder' : name;
  final now = DateTime.now().toLocal();
  var message = 'Emergency: $who pressed SOS at $now';
  if (location?['latitude'] is num && location?['longitude'] is num) {
    message +=
        '\nhttps://maps.google.com/?q=${location!['latitude']},${location['longitude']}';
  }
  try {
    List<Map<String, dynamic>>? pairs;
    for (var attempt = 0; attempt < 2 && pairs == null; attempt++) {
      try {
        pairs = await db
            .from('pairings')
            .select('id')
            .eq('primary_id', user.id)
            .eq('status', 'accepted')
            .timeout(const Duration(seconds: 6));
      } catch (_) {}
    }
    if (pairs == null || pairs.isEmpty) return false;
    final results = await Future.wait(
      pairs.map((pair) async {
        dynamic id;
        for (var attempt = 0; attempt < 2 && id == null; attempt++) {
          try {
            id = await db
                .rpc(
                  'send_message',
                  params: {'pairing': pair['id'], 'message': message},
                )
                .timeout(const Duration(seconds: 5));
          } catch (_) {}
        }
        if (id == null) {
          return false;
        }
        var notified = false;
        for (var attempt = 0; attempt < 2 && !notified; attempt++) {
          try {
            final response = await db.functions
                .invoke('notify-message', body: {'message_id': id})
                .timeout(const Duration(seconds: 5));
            notified =
                response.status == 200 &&
                response.data is Map &&
                (response.data['attempted'] as num? ?? 0) > 0;
          } catch (_) {}
        }
        return notified;
      }),
    );
    return results.every((result) => result);
  } catch (_) {
    return false;
  }
}
