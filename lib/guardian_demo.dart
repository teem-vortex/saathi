import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const androidControls = MethodChannel('saathi/android');
const demoElderName = 'Meera';
const elderScenarioKey = 'demo_elder_scenario';
const _alertKey = 'demo_alerts';

enum Scenario { typical, high, low, missing }

class GuardianDemo extends StatelessWidget {
  const GuardianDemo({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Health overview',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const Text('Demo data · Fictional people and readings'),
      const SizedBox(height: 16),
      Card(
        child: ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Alerts'),
          subtitle: const Text('Review simulated reading alerts'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const DemoAlerts()),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text('People', style: Theme.of(context).textTheme.titleLarge),
      for (final name in [demoElderName, 'Ravi'])
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => DemoReadings(name: name)),
            ),
          ),
        ),
    ],
  );
}

class DemoReadings extends StatefulWidget {
  const DemoReadings({super.key, required this.name});
  final String name;

  @override
  State<DemoReadings> createState() => _DemoReadingsState();
}

class _DemoReadingsState extends State<DemoReadings> {
  Scenario scenario = Scenario.typical;
  DateTime recorded = DateTime.now();
  bool saving = false;

  Future<void> loadScenario(Scenario next) async {
    final time = DateTime.now();
    setState(() {
      scenario = next;
      recorded = time;
      saving = true;
    });
    try {
      if (widget.name == demoElderName) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(elderScenarioKey, next.name);
      }
      if (next != Scenario.high && next != Scenario.low) return;
      final reading = next == Scenario.high
          ? 'Blood pressure above demo range · 155/95 mmHg'
          : 'Oxygen below demo range · 89%';
      final preferences = await SharedPreferences.getInstance();
      final alerts = preferences.getStringList(_alertKey) ?? [];
      alerts.insert(
        0,
        jsonEncode([widget.name, reading, time.toIso8601String()]),
      );
      if (!await preferences.setStringList(_alertKey, alerts)) {
        throw StateError('Could not save alert');
      }
      final shown = !kIsWeb && (await androidControls.invokeMethod<bool>('notify') ?? false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shown
                  ? 'Demo alert saved and notification posted.'
                  : 'Demo alert saved. Notifications are off.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not complete the demo alert. Check Alerts for the saved record.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readings = [
      (
        'Blood pressure',
        scenario == Scenario.high ? '155/95 mmHg' : '118/76 mmHg',
        Icons.monitor_heart_outlined,
        scenario == Scenario.high,
      ),
      (
        'Oxygen saturation',
        scenario == Scenario.low ? '89%' : '98%',
        Icons.air,
        scenario == Scenario.low,
      ),
      ('Heart rate', '72 bpm', Icons.favorite_outline, false),
      ('Temperature', '36.6 °C', Icons.thermostat, false),
      ('Respiratory rate', '16 breaths/min', Icons.rotate_right, false),
      ('Activity', '2,450 steps', Icons.directions_walk, false),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Synthetic readings for testing'),
          Text(
            scenario == Scenario.missing
                ? 'No readings available'
                : 'Recorded ${formatDemoTime(recorded)}',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, label) in [
                (Scenario.typical, 'Typical'),
                (Scenario.high, 'High BP test'),
                (Scenario.low, 'Low oxygen test'),
                (Scenario.missing, 'Missing data'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: value == scenario,
                  onSelected: saving ? null : (_) => loadScenario(value),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (label, value, icon, flagged) in readings)
                  SizedBox(
                    width: constraints.maxWidth < 340
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: flagged
                          ? Theme.of(context).colorScheme.errorContainer
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon),
                            const SizedBox(height: 10),
                            Text(label),
                            Text(
                              scenario == Scenario.missing
                                  ? 'Unavailable'
                                  : value,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (flagged) const Text('Outside demo range'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatDemoTime(DateTime time) =>
    time.toLocal().toString().substring(0, 16);

class DemoAlerts extends StatefulWidget {
  const DemoAlerts({super.key});

  @override
  State<DemoAlerts> createState() => _DemoAlertsState();
}

class _DemoAlertsState extends State<DemoAlerts> {
  late final alerts = SharedPreferences.getInstance().then(
    (preferences) => preferences.getStringList(_alertKey) ?? <String>[],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alerts')),
    body: FutureBuilder<List<String>>(
      future: alerts,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load alerts.'));
        }
        final records = snapshot.data;
        if (records == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (records.isEmpty) {
          return const Center(child: Text('No demo alerts yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = jsonDecode(records[index]) as List<dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text('${record[0]} · Demo alert'),
                subtitle: Text(
                  '${record[1]}\nRecorded ${formatDemoTime(DateTime.parse(record[2] as String))}',
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
