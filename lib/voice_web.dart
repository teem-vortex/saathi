import 'dart:js_interop';

import 'package:flutter/services.dart';

@JS('saathiVoice')
external JSPromise<JSString> _voice(
  JSString method,
  JSString lang,
  JSString text,
);
Future<String?> voiceCall(String method, [Map<String, String>? args]) async {
  try {
    return (await _voice(
      method.toJS,
      (args?['language'] ?? 'en-IN').toJS,
      (args?['text'] ?? '').toJS,
    ).toDart).toDart;
  } catch (error) {
    throw PlatformException(
      code: 'speech',
      message: 'Browser speech service: $error',
    );
  }
}
