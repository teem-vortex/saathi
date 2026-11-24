import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'voice_native.dart' if (dart.library.js_interop) 'voice_web.dart';
import 'connections.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

String voiceLocale(String language) => switch (language) {
  'தமிழ்' => 'ta-IN',
  'ಕನ್ನಡ' => 'kn-IN',
  'తెలుగు' => 'te-IN',
  'മലയാളം' => 'ml-IN',
  _ => 'en-IN',
};

class VoiceDraftPage extends StatefulWidget {
  const VoiceDraftPage({
    super.key,
    required this.language,
    this.initialDraft,
    this.fromWatch = false,
  });
  final String language;
  final String? initialDraft;
  final bool fromWatch;
  @override
  State<VoiceDraftPage> createState() => _VoiceDraftPageState();
}

class _VoiceDraftPageState extends State<VoiceDraftPage> {
  final message = TextEditingController();
  @override
  void initState() {
    super.initState();
    message.text = widget.initialDraft ?? '';
  }

  bool busy = false;
  bool sending = false;
  bool sent = false;
  String? status;

  Future<void> send() async {
    if (sending) return;
    final text = message.text.trim();
    if (text.isEmpty) {
      setState(() => status = 'Speak or type a message first.');
      return;
    }
    if (!messagingConfigured ||
        Supabase.instance.client.auth.currentUser == null) {
      setState(
        () => status = 'Sign in and connect a guardian before sending. Your message has not been sent.',
      );
      return;
    }
    try {
      final db = Supabase.instance.client;
      final user = db.auth.currentUser!;
      final pairs = await db
          .from('pairings')
          .select()
          .eq('status', 'accepted')
          .eq('primary_id', user.id);
      if (!mounted) return;
      if (pairs.isEmpty) {
        setState(
          () => status =
              'No guardian is connected. Your message has not been sent.',
        );
        return;
      }
      final selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose a guardian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text),
                for (final pair in pairs)
                  ListTile(
                    title: Text(
                      'Guardian ${((pair['guardian_id']) as String).substring(0, 8)}',
                    ),
                    subtitle: const Text('Tap to confirm and send'),
                    onTap: () => Navigator.pop(context, pair['id'] as String),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      setState(() => sending = true);
      final messageId = await db.rpc(
        'send_message',
        params: {'pairing': selected, 'message': text},
      );
      sent = true;
      var draftStatus = '';
      if (widget.fromWatch) {
        try {
          final cleared = await const MethodChannel('saathi/android')
              .invokeMethod<bool>('clearWatchDraft');
          if (cleared != true) {
            draftStatus = ' The watch draft could not be cleared.';
          }
        } catch (_) {
          draftStatus = ' The watch draft could not be cleared.';
        }
      }
      var notificationStatus = 'Notification could not be confirmed.';
      try {
        final response = await db.functions.invoke(
          'notify-message',
          body: {'message_id': messageId},
        );
        final data = response.data;
        if (response.status == 200 &&
            data is Map &&
            (data['attempted'] as num? ?? 0) > 0) {
          notificationStatus = 'Notification requested.';
        } else if (response.status == 200) {
          notificationStatus =
              'Guardian has no registered notification device.';
        }
      } catch (_) {
        /* Message remains saved even if the notification fails. */
      }
      if (mounted) {
        setState(
          () => status =
              'Message saved in Saathi. $notificationStatus$draftStatus',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => status = 'Could not send. Your draft is still here. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> listen() async {
    setState(() {
      busy = true;
      status = null;
    });
    try {
      final words = await voiceCall('listen', {
        'language': voiceLocale(widget.language),
      });
      if (!mounted || words == null || words.trim().isEmpty) return;
      final transcript = words.trim();
      final command = RegExp(
        r'^(?:please\s+)?send (?:it|this|the message)(?: to (?:the )?(?:guardian|secondary user))?[.!]?$',
        caseSensitive: false,
      );
      if (command.hasMatch(transcript)) {
        await send();
      } else {
        message.text = message.text.trim().isEmpty
            ? transcript
            : '${message.text.trim()} $transcript';
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => status = error.message ?? 'Speech recognition is unavailable.',
        );
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => status = 'Speech recognition is unavailable on this device.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> speak() async {
    try {
      await voiceCall('speak', {
        'text': message.text.trim(),
        'language': voiceLocale(widget.language),
      });
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => status = error.message ?? 'Could not read the message.');
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => status = 'Text-to-speech is unavailable on this device.',
        );
      }
    }
  }

  @override
  void dispose() {
    voiceCall('stopSpeaking').catchError((_) => null);
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Talk to Saathi')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Voice message draft',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Speak or type a message. Your speech service may use the internet.',
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: busy
              ? (kIsWeb ? () => voiceCall('stopListening') : null)
              : listen,
          icon: Icon(busy && kIsWeb ? Icons.stop : Icons.mic),
          label: Text(
            busy && kIsWeb
                ? 'Finish listening'
                : busy
                ? 'Listening…'
                : 'Speak message',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: message,
          minLines: 3,
          maxLines: 8,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Message draft',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: message.text.trim().isEmpty ? null : speak,
          icon: const Icon(Icons.volume_up),
          label: const Text('Read draft aloud'),
        ),
        FilledButton.icon(
          onPressed: busy || sending || sent ? null : send,
          icon: const Icon(Icons.send),
          label: const Text('Send to guardian'),
        ),
        const Text(
          'Sign in and link your guardian using Saathi connections before sending.',
        ),
        if (widget.fromWatch)
          TextButton(
            onPressed: () async {
              final discard = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Discard watch draft?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
              if (discard != true || !context.mounted) return;
              await const MethodChannel('saathi/android')
                  .invokeMethod<bool>('clearWatchDraft');
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Discard watch draft'),
          ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(status!),
          ),
      ],
    ),
  );
}
