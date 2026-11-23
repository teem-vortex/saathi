import 'package:flutter/services.dart';
const _channel = MethodChannel('saathi/android');
Future<String?> voiceCall(String method, [Map<String,String>? args]) async {
  if (method == 'listen') return _channel.invokeMethod<String>(method, args);
  await _channel.invokeMethod<void>(method, args);
  return null;
}
