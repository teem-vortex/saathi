import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const _project = String.fromEnvironment('FIREBASE_PROJECT_ID');
bool _ready = false;
StreamSubscription<String>? _tokenChanges;
String? _registeredToken;

Future<void> initializePush() async {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android ||
      [_apiKey, _appId, _sender, _project].any((value) => value.isEmpty)) {
    return;
  }
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _sender,
      projectId: _project,
    ),
  );
  _ready = true;
}

Future<bool> registerPush() async {
  if (!_ready) return false;
  final messaging = FirebaseMessaging.instance;
  final permission = await messaging.requestPermission();
  if (permission.authorizationStatus == AuthorizationStatus.denied) {
    return false;
  }
  await _tokenChanges?.cancel();
  final firstRegistration = Completer<bool>();
  _tokenChanges = messaging.onRegistered.listen((newToken) async {
    if (Supabase.instance.client.auth.currentUser != null) {
      try {
        await Supabase.instance.client.rpc(
          'register_push_token',
          params: {'device_token': newToken},
        );
        _registeredToken = newToken;
        if (!firstRegistration.isCompleted) firstRegistration.complete(true);
      } catch (_) {
        if (!firstRegistration.isCompleted) firstRegistration.complete(false);
      }
    }
  });
  await messaging.register();
  return firstRegistration.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => false,
  );
}

Future<void> unregisterPush() async {
  await _tokenChanges?.cancel();
  _tokenChanges = null;
  if (!_ready) return;
  final token = _registeredToken;
  if (token != null) {
    await Supabase.instance.client.rpc(
      'unregister_push_token',
      params: {'device_token': token},
    );
  }
  _registeredToken = null;
}
