import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'guardian_demo.dart' show androidControls;

String appKey(Map app) => '${app['package']}/${app['activity']}';

Future<List<Map<String, dynamic>>> installedApps() async {
  final list = await androidControls.invokeListMethod<dynamic>('apps') ?? [];
  return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}

Future<void> launchSelectedApp(
  BuildContext context,
  Map<String, dynamic> app,
) async {
  final success =
      await androidControls.invokeMethod<bool>('launchApp', app) ?? false;
  if (!success && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('App unavailable')));
  }
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.app, {super.key});
  final Map<String, dynamic> app;

  @override
  Widget build(BuildContext context) {
    final bytes = app['icon'];
    return bytes is Uint8List
        ? Image.memory(bytes, width: 40, height: 40)
        : const Icon(Icons.apps, size: 40);
  }
}

class LauncherSettings extends StatefulWidget {
  const LauncherSettings({
    super.key,
    required this.enabled,
    required this.onDisabledTap,
  });
  final bool enabled;
  final VoidCallback onDisabledTap;
  @override
  State<LauncherSettings> createState() => _LauncherSettingsState();
}

class _LauncherSettingsState extends State<LauncherSettings> {
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      if (mounted) setState(() => prefs = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = prefs;
    if (store == null) return const Center(child: CircularProgressIndicator());
    final normal = store.getBool('launcherNormal') ?? false;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? null : widget.onDisabledTap,
            child: AbsorbPointer(
              absorbing: !widget.enabled,
              child: Opacity(
                opacity: widget.enabled ? 1 : 0.45,
                child: DropdownButtonFormField<bool>(
                  initialValue: normal,
                  decoration: const InputDecoration(
                    labelText: 'Launcher type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: false, child: Text('Minimal')),
                    DropdownMenuItem(
                      value: true,
                      child: Text('Normal (with app menu)'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await store.setBool('launcherNormal', value);
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
          ),
        ),
        if (normal) ...[
          launcherOption(
            icon: Icons.apps,
            title: 'Choose app menu apps',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AppPicker(prefs: store, pinned: false),
              ),
            ),
          ),
          launcherOption(
            icon: Icons.add_box_outlined,
            title: 'Add app as tile',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AppPicker(prefs: store, pinned: true),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget launcherOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.45,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: widget.enabled ? onTap : widget.onDisabledTap,
      ),
    );
  }
}

class AppPicker extends StatefulWidget {
  const AppPicker({super.key, required this.prefs, required this.pinned});
  final SharedPreferences prefs;
  final bool pinned;
  @override
  State<AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends State<AppPicker> {
  late bool all = widget.prefs.getBool('launcherAllApps') ?? true;
  late Set<String> selected =
      (widget.prefs.getStringList(
                widget.pinned ? 'launcherPinned' : 'launcherSelected',
              ) ??
              [])
          .toSet();
  late Future<List<Map<String, dynamic>>> apps = installedApps();

  Future<void> save() async {
    await widget.prefs.setStringList(
      widget.pinned ? 'launcherPinned' : 'launcherSelected',
      selected.toList(),
    );
    if (!widget.pinned) await widget.prefs.setBool('launcherAllApps', all);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.pinned ? 'Add app as tile' : 'Choose app menu apps'),
      actions: [TextButton(onPressed: save, child: const Text('Save'))],
    ),
    body: FutureBuilder(
      future: apps,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load apps'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: [
            if (!widget.pinned)
              SwitchListTile(
                title: const Text('All apps'),
                subtitle: const Text('Turn off to choose individual apps'),
                value: all,
                onChanged: (value) => setState(() => all = value),
              ),
            for (final app in snapshot.data!)
              CheckboxListTile(
                secondary: AppIcon(app),
                title: Text(app['label'] as String),
                value: all && !widget.pinned || selected.contains(appKey(app)),
                onChanged: all && !widget.pinned
                    ? null
                    : (value) => setState(() {
                        if (value == true) {
                          selected.add(appKey(app));
                        } else {
                          selected.remove(appKey(app));
                        }
                      }),
              ),
          ],
        );
      },
    ),
  );
}

class LauncherAppMenu extends StatefulWidget {
  const LauncherAppMenu({super.key});
  @override
  State<LauncherAppMenu> createState() => _LauncherAppMenuState();
}

class _LauncherAppMenuState extends State<LauncherAppMenu>
    with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> apps = load();
  Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final list = await installedApps();
    final selected = (prefs.getStringList('launcherSelected') ?? []).toSet();
    return (prefs.getBool('launcherAllApps') ?? true)
        ? list
        : list.where((app) => selected.contains(appKey(app))).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() => apps = load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: const Text('Apps'),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: Container(color: const Color(0x88000000)),
    ),
    body: FutureBuilder(
      future: apps,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load apps'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                if (!context.mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => AppPicker(prefs: prefs, pinned: false),
                  ),
                );
                setState(() => apps = load());
              },
              child: const Text('Choose apps'),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: list.length > 10 ? 3 : 2,
            mainAxisExtent: 150,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) => Card(
            child: InkWell(
              onTap: () => launchSelectedApp(context, list[index]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(list[index]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      list[index]['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
