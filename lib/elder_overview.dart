import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'guardian_demo.dart' show Scenario, demoElderName, elderScenarioKey;

// A future summary provider receives the selected language and the flagged
// metric identifiers. The current provider formats the supplied demo facts.
typedef ElderSummaryRequest = ({
  String languageCode,
  Scenario scenario,
  List<String> flaggedMetrics,
});

const _copy = {
  'English': (
    'en',
    [
      'Good morning',
      'Good afternoon',
      'Good evening',
      'Demo readings are in range.',
      'Out of demo range',
      'Readings unavailable',
      'BP',
      'Oxygen',
      'Pulse',
      'Temp',
    ],
  ),
  'தமிழ்': (
    'ta',
    [
      'காலை வணக்கம்',
      'மதிய வணக்கம்',
      'மாலை வணக்கம்',
      'மாதிரி அளவுகள் வரம்பிற்குள் உள்ளன.',
      'மாதிரி வரம்பிற்கு வெளியே',
      'அளவுகள் கிடைக்கவில்லை',
      'இரத்த அழுத்தம்',
      'ஆக்சிஜன்',
      'நாடித்துடிப்பு',
      'வெப்பம்',
    ],
  ),
  'ಕನ್ನಡ': (
    'kn',
    [
      'ಶುಭೋದಯ',
      'ಶುಭ ಮಧ್ಯಾಹ್ನ',
      'ಶುಭ ಸಂಜೆ',
      'ಮಾದರಿ ಅಳತೆಗಳು ಮಿತಿಯಲ್ಲಿವೆ.',
      'ಮಾದರಿ ಮಿತಿಯ ಹೊರಗೆ',
      'ಅಳತೆಗಳು ಲಭ್ಯವಿಲ್ಲ',
      'ರಕ್ತದೊತ್ತಡ',
      'ಆಮ್ಲಜನಕ',
      'ನಾಡಿ',
      'ತಾಪಮಾನ',
    ],
  ),
  'తెలుగు': (
    'te',
    [
      'శుభోదయం',
      'శుభ మధ్యాహ్నం',
      'శుభ సాయంత్రం',
      'నమూనా కొలతలు పరిధిలో ఉన్నాయి.',
      'నమూనా పరిధికి వెలుపల',
      'కొలతలు అందుబాటులో లేవు',
      'రక్తపోటు',
      'ఆక్సిజన్',
      'నాడి',
      'ఉష్ణోగ్రత',
    ],
  ),
  'മലയാളം': (
    'ml',
    [
      'സുപ്രഭാതം',
      'ശുഭ ഉച്ച',
      'ശുഭ സായാഹ്നം',
      'മാതൃകാ അളവുകൾ പരിധിക്കുള്ളിലാണ്.',
      'മാതൃകാ പരിധിക്ക് പുറത്ത്',
      'അളവുകൾ ലഭ്യമല്ല',
      'രക്തസമ്മർദ്ദം',
      'ഓക്സിജൻ',
      'നാഡിമിടിപ്പ്',
      'താപനില',
    ],
  ),
};

class ElderOverview extends StatefulWidget {
  const ElderOverview({super.key, required this.language});
  final String language;

  @override
  State<ElderOverview> createState() => _ElderOverviewState();
}

class _ElderOverviewState extends State<ElderOverview> {
  late final scenario = SharedPreferences.getInstance().then((preferences) {
    final stored = preferences.getString(elderScenarioKey);
    return Scenario.values.asNameMap()[stored] ?? Scenario.typical;
  });

  @override
  Widget build(BuildContext context) {
    final (code, labels) = _copy[widget.language] ?? _copy['English']!;
    final hour = DateTime.now().hour;
    final greeting =
        labels[hour < 12
            ? 0
            : hour < 17
            ? 1
            : 2];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $demoElderName',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          FutureBuilder<Scenario>(
            future: scenario,
            builder: (context, snapshot) {
              final current = snapshot.data ?? Scenario.missing;
              final flagged = switch (current) {
                Scenario.high => ['bloodPressure'],
                Scenario.low => ['oxygenSaturation'],
                _ => <String>[],
              };
              final request = (
                languageCode: code,
                scenario: current,
                flaggedMetrics: flagged,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localSummary(request)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (final (key, label) in [
                        ('bloodPressure', labels[6]),
                        ('oxygenSaturation', labels[7]),
                        ('pulse', labels[8]),
                        ('temperature', labels[9]),
                      ])
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              current == Scenario.missing
                                  ? Icons.remove
                                  : flagged.contains(key)
                                  ? Icons.warning_amber_rounded
                                  : Icons.check,
                              color: current == Scenario.missing
                                  ? null
                                  : flagged.contains(key)
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Text(label),
                          ],
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

String localSummary(ElderSummaryRequest request) {
  final labels = _copy.values
      .firstWhere((entry) => entry.$1 == request.languageCode)
      .$2;
  if (request.scenario == Scenario.missing) return labels[5];
  if (request.flaggedMetrics.isEmpty) return labels[3];
  final metrics = request.flaggedMetrics.map(
    (metric) => metric == 'bloodPressure' ? labels[6] : labels[7],
  );
  return '${labels[4]} · ${metrics.join(', ')}';
}
