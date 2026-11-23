import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'elder_overview.dart';
import 'launcher_options.dart';

class ElderLauncher extends StatefulWidget {
  const ElderLauncher({
    super.key,
    required this.preferences,
    required this.labelsFor,
    required this.openSettings,
    required this.openAction,
  });

  final SharedPreferences? preferences;
  final List<String> Function(String) labelsFor;
  final Future<void> Function(BuildContext, String, ValueChanged<String>)
  openSettings;
  final void Function(BuildContext, int, String) openAction;

  @override
  State<ElderLauncher> createState() => _ElderLauncherState();
}

class _ElderLauncherState extends State<ElderLauncher>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> pinnedApps = [];
  bool normal = false;
  Animation<double>? appsTransition;

  Future<void> openApps() async {
    if (appsTransition != null) return;
    final route = PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => const LauncherAppMenu(),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: const Interval(0.5, 1, curve: Curves.easeInOut)),
        ),
        child: child,
      ),
    );
    Navigator.push(context, route);
    setState(() => appsTransition = route.animation);
    await route.completed;
    if (mounted) setState(() => appsTransition = null);
  }

  late String language = widget.preferences?.getString('language') ?? 'English';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshPreferences();
  }

  Future<void> refreshPreferences() async {
    await widget.preferences?.reload();
    final allApps = await installedApps();
    final pinned = (widget.preferences?.getStringList('launcherPinned') ?? [])
        .toSet();
    if (!mounted) return;
    setState(() {
      language = widget.preferences?.getString('language') ?? language;
      normal = widget.preferences?.getBool('launcherNormal') ?? false;
      pinnedApps = allApps
          .where((app) => pinned.contains(appKey(app)))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labelsFor(language);
    final topInset = MediaQuery.paddingOf(context).top;
    const icons = [
      Icons.mic_none,
      Icons.volume_up_outlined,
      Icons.favorite_border,
      Icons.phone_outlined,
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset,
              child: const ColoredBox(color: Color(0x88000000)),
            ),
            FadeTransition(
              opacity: appsTransition != null
                  ? ReverseAnimation(appsTransition!).drive(
                      CurveTween(
                        curve: const Interval(0.5, 1, curve: Curves.easeInOut),
                      ),
                    )
                  : const AlwaysStoppedAnimation(1.0),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton.filledTonal(
                        tooltip: labels[5],
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () async {
                          await widget.openSettings(context, language, (value) {
                            setState(() => language = value);
                            widget.preferences?.setString('language', value);
                          });
                          await refreshPreferences();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(child: ElderOverview(language: language)),
                    const SizedBox(height: 8),
                    for (var row = 0; row < icons.length; row += 2)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var index = row; index < row + 2; index++)
                              Expanded(
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => widget.openAction(
                                      context,
                                      index,
                                      labels[14],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(icons[index], size: 38),
                                          const SizedBox(height: 8),
                                          Text(
                                            labels[10 + index],
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Wrap(
                      children: [
                        if (normal)
                          SizedBox(
                            width: (MediaQuery.sizeOf(context).width - 32) / 2,
                            child: Card(
                              child: ListTile(
                                leading: const Icon(Icons.apps),
                                title: const Text('Apps'),
                                onTap: openApps,
                              ),
                            ),
                          ),
                        for (final app in pinnedApps)
                          SizedBox(
                            width: (MediaQuery.sizeOf(context).width - 32) / 2,
                            child: Card(
                              child: ListTile(
                                leading: AppIcon(app),
                                title: Text(app['label'] as String),
                                onTap: () => launchSelectedApp(context, app),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
