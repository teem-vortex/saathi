import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_notifications.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
bool get messagingConfigured =>
    supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key, required this.elder});
  final bool elder;
  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  String? info;
  String? invite;
  bool busy = false;
  List<Map<String, dynamic>> pairs = [];
  SupabaseClient get db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (messagingConfigured && db.auth.currentUser != null) run(refresh);
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      info = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => info = e.message);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => info = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => info = 'Could not connect. Check your internet connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> refresh() async {
    final records = await db
        .from('pairings')
        .select()
        .neq('status', 'revoked')
        .order('created_at', ascending: false);
    if (mounted) {
      setState(() => pairs = List<Map<String, dynamic>>.from(records));
    }
  }

  Future<void> refreshAfterSignIn() async {
    try {
      await registerPush();
    } catch (_) {
      // Signing in and reading messages must still work without push.
    }
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!messagingConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saathi connections')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Saathi connections are not configured yet. The development project must be connected before accounts and messages can work.',
          ),
        ),
      );
    }
    final user = db.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Saathi connections')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (user == null) ...[
            const Text(
              'Sign in or create an account to connect with your family.',
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => run(() async {
                      await db.auth.signInWithPassword(
                        email: email.text.trim(),
                        password: password.text,
                      );
                      password.clear();
                      await refreshAfterSignIn();
                    }),
              child: const Text('Sign in'),
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => run(() async {
                      final response = await db.auth.signUp(
                        email: email.text.trim(),
                        password: password.text,
                      );
                      password.clear();
                      if (response.session == null) {
                        if (mounted) {
                          setState(
                            () => info = 'Check your email to confirm your account, then sign in.',
                          );
                        }
                      } else {
                        await refreshAfterSignIn();
                      }
                    }),
              child: const Text('Create account'),
            ),
          ] else ...[
            Text('Signed in as ${user.email ?? 'Saathi user'}'),
            if (widget.elder) ...[
              const Text(
                'Share this code with your guardian. It expires in 10 minutes.',
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        if (mounted) setState(() => invite = null);
                        final value = await db.rpc('create_pairing_code');
                        if (mounted) setState(() => invite = value as String);
                      }),
                child: const Text('Code for guardian'),
              ),
              if (invite != null) SelectableText(invite!),
            ] else ...[
              const Text('Enter the code shown on the elder’s phone.'),
              TextField(
                controller: code,
                decoration: const InputDecoration(labelText: 'Pairing code'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        await db.rpc(
                          'connect_elder',
                          params: {'code': code.text.trim()},
                        );
                        try {
                          await registerPush();
                        } catch (_) {
                          /* Messages remain accessible in the app. */
                        }
                        code.clear();
                        await refresh();
                        if (mounted) {
                          setState(() => info = 'Elder connected.');
                        }
                      }),
                child: const Text('Add elder'),
              ),
            ],
            OutlinedButton(
              onPressed: busy ? null : () => run(refresh),
              child: const Text('Refresh connections'),
            ),
            for (final pair in pairs)
              Card(
                child: ListTile(
                  title: Text(
                    pair['status'] == 'accepted'
                        ? 'Connected user'
                        : 'Connection request',
                  ),
                  subtitle: Text(
                    'Account ${((pair['primary_id'] == user.id ? pair['guardian_id'] : pair['primary_id']) as String).substring(0, 8)} · ${pair['status']}',
                  ),
                  trailing:
                      pair['status'] == 'pending' &&
                          pair['guardian_id'] == user.id
                      ? Wrap(
                          children: [
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => run(() async {
                                      await db.rpc(
                                        'respond_pairing',
                                        params: {
                                          'pairing': pair['id'],
                                          'accept_request': true,
                                        },
                                      );
                                      await refresh();
                                    }),
                              child: const Text('Accept'),
                            ),
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => run(() async {
                                      await db.rpc(
                                        'respond_pairing',
                                        params: {
                                          'pairing': pair['id'],
                                          'accept_request': false,
                                        },
                                      );
                                      await refresh();
                                    }),
                              child: const Text('Decline'),
                            ),
                          ],
                        )
                      : TextButton(
                          onPressed: busy
                              ? null
                              : () => run(() async {
                                  await db.rpc(
                                    'revoke_pairing',
                                    params: {'pairing': pair['id']},
                                  );
                                  await refresh();
                                }),
                          child: const Text('Remove'),
                        ),
                ),
              ),
            if (pairs.any((p) => p['status'] == 'accepted'))
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const MessagesPage()),
                ),
                child: const Text('Open messages'),
              ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => run(() async {
                      try {
                        await unregisterPush();
                      } catch (_) {
                        /* Sign out even if the token cannot be removed. */
                      }
                      await db.auth.signOut();
                      if (mounted) {
                        setState(() {
                          pairs = [];
                          invite = null;
                        });
                      }
                    }),
              child: const Text('Sign out'),
            ),
          ],
          if (info != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(info!),
            ),
        ],
      ),
    );
  }
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late Future<List<Map<String, dynamic>>> messages = load();
  Future<List<Map<String, dynamic>>> load() async =>
      List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .from('messages')
            .select()
            .order('created_at', ascending: false)
            .limit(100),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Messages'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => setState(() => messages = load()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: messages,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load messages.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No messages yet.'));
        }
        return ListView(
          children: [
            for (final item in snapshot.data!)
              ListTile(
                title: Text(item['body'] as String),
                subtitle: Text(item['created_at'] as String),
              ),
          ],
        );
      },
    ),
  );
}
