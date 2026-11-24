import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'connections.dart';
import 'push_notifications.dart';

const authRedirect = 'com.teemvortex.saathi://login-callback/';

class SignInGate extends StatefulWidget {
  const SignInGate({super.key, required this.child});
  final Widget child;

  @override
  State<SignInGate> createState() => _SignInGateState();
}

class _SignInGateState extends State<SignInGate> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? message;
  StreamSubscription<AuthState>? authChanges;

  @override
  void initState() {
    super.initState();
    if (messagingConfigured) {
      authChanges = Supabase.instance.client.auth.onAuthStateChange.listen((
        state,
      ) {
        if (state.event == AuthChangeEvent.signedIn) {
          unawaited(registerPush().then<void>((_) {}, onError: (_) {}));
        }
      });
    }
  }

  @override
  void dispose() {
    authChanges?.cancel();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Could not sign in. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!messagingConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sign in')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sign-in is not configured. Please contact the app administrator.',
          ),
        ),
      );
    }
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (auth.currentSession != null) return widget.child;
        return Scaffold(
          appBar: AppBar(title: const Text('Sign in to Saathi')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Sign in or create an account to continue.'),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        await auth.signInWithPassword(
                          email: email.text.trim(),
                          password: password.text,
                        );
                        password.clear();
                      }),
                child: const Text('Sign in'),
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        final result = await auth.signUp(
                          email: email.text.trim(),
                          password: password.text,
                        );
                        password.clear();
                        if (result.session == null && mounted) {
                          setState(
                            () => message = 'Check your email to confirm your account, then sign in.',
                          );
                        }
                      }),
                child: const Text('Create account'),
              ),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        final launched = await auth.signInWithOAuth(
                          OAuthProvider.google,
                          redirectTo: kIsWeb ? null : authRedirect,
                        );
                        if (!launched) {
                          throw Exception('Could not open browser');
                        }
                      }),
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Continue with Google'),
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(message!),
                ),
            ],
          ),
        );
      },
    );
  }
}
