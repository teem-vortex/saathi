# Saathi Wear OS implementation plan

**Status:** Partially implemented on the local `smartwatch` branch. See the work log for verified behavior and remaining work.  
**Minimum:** Wear OS 4 (Android 13, API 33).  
**Current test device:** `Wear_OS_Small_Round`, x86_64, 384 × 384 physical pixels at 320 dpi, currently `emulator-5554`.

## 1. Create a separate watch build

1. Add a watch application module, `:wear`, alongside the existing Flutter `:app` in the Android Gradle project. Use Kotlin and Compose for Wear OS for the round watch UI. Keep the phone and its Elder and Guardian screens in Flutter. A separate watch build keeps watch-specific launcher, voice, and permissions code out of the phone APK.
2. Set `minSdk = 33`. Select Wear Compose, Tiles, and complication dependencies compatible with that minimum. Verify the merged manifest and APK before installing. Declare `android.hardware.type.watch` and mark the watch app non-standalone for distribution because sending messages and loading live readings depend on Saathi on a paired phone.
3. Use the phone's current application ID and match signing certificates across phone and watch for the Wear Data Layer. Use a distinct Kotlin namespace for watch code. Keep the phone build's existing entry points and deployment configuration intact. Android Studio should expose a `wear` run configuration. Build the two apps separately and target the correct device explicitly when installing.
4. Separate the watch UI, local preferences and state, phone connection, and operating-system integration. Keep independent entry points for opening the app, Home, and the system assistant. Route Wear OS shortcuts through a small set of safe destinations with input validation.

[Wear OS app packaging](https://developer.android.com/training/wearables/packaging) · [Watch app manifest and standalone status](https://developer.android.com/training/wearables/apps/standalone-apps) · [Wear Data Layer identity requirements](https://developer.android.com/training/wearables/data/overview)

## 2. Build Elder Home and Settings

1. Open directly to Elder Home on every ordinary cold launch. Put a localized time-of-day greeting, the elder's name when available, and a compact health summary above the action buttons. Show only a few statuses on the home screen, such as blood pressure, oxygen, and pulse. A separate readings screen can show individual values, units, and recorded time.
2. Use short, full-width scrolling buttons with a distinct icon and label for Talk to Saathi, Hear messages, I’m okay, and Ask for a call. Use the same action order and wording as the phone. Use round-screen insets and space the first and last items so they can scroll clear of the curved edges. Add readable touch targets, TalkBack labels, a rotary scroll path, and visible status text alongside any check or warning icon.
3. Keep the Settings gear visible near the top of Elder Home. Include persisted language and appearance settings, companion connection status, Launcher, Assistant, and quick-access setup. Use English, Tamil, Kannada, Telugu, and Malayalam. Default to the device's supported language or English and follow the device appearance by default. Keep a touch route to every voice action.
4. Show meaningful first-run states without a linked phone. Provide a labeled demo for emulator verification, including typical, flagged, missing, and stale readings. Leave live summaries unavailable until readings arrive. Show their capture time and source, and use plain text such as “No recent reading” when data is missing. Display a labeled status alongside any alert icon.

[Wear OS UI surfaces and Compose guidance](https://developer.android.com/training/wearables/user-interfaces)

## 3. Connect the watch to the existing Elder phone app

| Watch action | Behavior |
| --- | --- |
| Talk to Saathi | Open a voice draft, show the recognized text, and allow edit, confirmation, or cancellation. Hand a confirmed draft to the paired Elder phone for review and sending through the existing guardian message flow. |
| Hear messages | Ask the eligible phone app for a recent message the elder can access. Show sender and time when authorized, and let the elder choose whether to play it aloud. |
| I’m okay | Prepare a short check-in draft for review on the phone. |
| Ask for a call | Prepare a callback-request draft for review on the phone. |

1. Advertise the companion capabilities on both devices. Distinguish missing companion, disconnected watch, signed-out elder, and connected elder with no approved guardian. Start an operation only with an eligible active phone. Keep phone sign-in, guardian selection, consent, database access, and notification delivery in the existing phone flow.
2. Exchange minimal, versioned payloads through the Wear Data Layer. Label requests with an ID, type, and expiry. Send only the readings necessary for the agreed watch summary, with their recording times. Keep credentials and raw microphone audio out of the link. Clear linked personal content on sign-out, revocation, or an account change. Keep private details inside the app, away from the watch face and Tile.
3. Reuse the phone's guardian draft screen for the actual send. Limit each handoff ID to one draft. A lost reply must never trigger an automatic second send. Show “Draft ready on phone” once the phone accepts the handoff. Show “Sent” only if the phone confirms the existing server write, and treat push delivery as a separate result. If the watch disconnects, keep the draft local for the elder to retry explicitly.
4. Test the connected path using a paired Android 13 phone emulator, the watch emulator, and synthetic accounts and readings. Keep the existing phone-side Health Connect design. Watch sensor collection and ElevenLabs require their own integrations and are outside this implementation.

[Wear Data Layer overview](https://developer.android.com/training/wearables/data/overview)

## 4. Make Saathi an optional watch launcher

On the running emulator, the role dump shows Home and Assistant. The stock Home resolves to `com.google.android.wearable.sysui`. Android also resolves its Default apps screen. The next check is whether the watch lets the elder select Saathi through that UI and whether canonical Home actions keep working.

1. Implement a dedicated watch Home activity and declare the system Home intent filter for that entry point. Draw the same watch Elder Home content with a separate launcher root. Home always returns to that root. Back from Settings, voice, or readings returns to Elder Home. Preserve the watch's system controls and offer a way to open the system app list or settings where the OS supports it.
2. In Elder Settings → Launcher, display **Set Saathi as Home**, **Active**, **Change Home app**, or an explanation that the watch cannot select Saathi. Check role availability and the actual holder independently, catch unavailable picker activities, and refresh when the app resumes. Request any change through the system's user-facing role picker or settings.
3. Before accepting the launcher on a target watch, verify the restore path using the watch UI alone. Canceling leaves the current launcher selected. Once active, verify the Home button, returning after other apps, Settings access, system navigation, lock and wake, reboot, and reverting to the stock launcher. Verify access to normal system functions such as the watch face and system app list. Keep the launcher option unavailable on devices where the app cannot establish a safe recovery path. Use emulator-only recovery commands during development if needed. They do not count as passing the user flow.
4. Implement a swipeable Saathi Tile and an optional watch-face complication. Both should open the watch app directly. Test installation and configuration on the stock launcher. Keep quick access available regardless of the Home selection.

[Android role availability](https://developer.android.com/reference/androidx/core/role/RoleManagerCompat) · [Wear OS Tile interactions](https://developer.android.com/training/wearables/tiles/interactions) · [Watch-face complications](https://developer.android.com/training/wearables/user-interfaces#complications)

## 5. Add Saathi Assistant with explicit microphone use

1. Implement tap-to-talk with the watch's available recognition UI, passing the chosen language where supported. Provide text input and localized cancellation, no recognizer, offline, and error states. Use the system voice entry where possible. Request direct microphone permission only if an implementation actually records audio. Stop listening on exit and ask for confirmation before sharing a draft. Use watch text-to-speech only on request for message playback and handle a missing voice or speaker.
2. Add the separate **Use Saathi as assistant** setting where the system supports it. Probe whether a dedicated `ACTION_ASSIST` entry can qualify and be selected. If Android selection or real invocation requires a voice-interaction service on the target, verify its eligibility before adding that route. A system invocation opens Saathi's voice screen and leaves the microphone idle until the elder chooses to speak. Keep this role independent of Home.
3. Exercise the watch's actual assistant control, cancellation, switching back, locked-screen handling, and a denied microphone. Require physical-device checks on Pixel Watch and Galaxy Watch before claiming button or role support. Tap-to-talk remains available on devices without default-assistant selection. The existing Saathi voice conversation provider integration is still pending.

[Wear OS voice input](https://developer.android.com/training/wearables/user-input/voice) · [Android voice interaction service](https://developer.android.com/reference/android/service/voice/VoiceInteractionService)

## 6. Build and verify in this order

| Checkpoint | Acceptance |
| --- | --- |
| Build and direct launch | Build `:wear:assembleDebug`, verify the APK's minimum and watch feature, install on the round API 33 AVD, and open directly to Elder Home. Run the existing Flutter build, analysis, and tests to catch phone regressions. |
| Round UI | Open every action and settings route. Check all five languages, large text, TalkBack, rotary scroll, clipped edges, dark/light appearance, reading states, and settings persistence after restart. |
| System roles and quick access | First prove availability, select/cancel/restore in watch UI, and test Home and assistant independently. Test Tile and complication entry on the stock Home. Record unsupported, selectable, and actually invokable as separate results. |
| Companion and voice | Pair with the API 33 phone AVD. Verify live phone handoff with test data, confirmed sends, no approved guardian, timeout, duplicate request, disconnected watch, and sign-out. Exercise voice cancellation, unavailable provider, and typed input. If the test backend is unavailable, record exactly which flow passed with fixtures and which still needs a live check. |
| Physical watches | Repeat role selection, stock restore, hardware buttons, reboot, audio, and pairing on a Pixel Watch and Galaxy Watch. Record model and OS build separately. Treat emulator verification and hardware verification as separate results. |

Run the module's lint and focused tests for greeting times, stale/missing data, role state, and draft handoff. Finish with a verified watch debug APK, Android Studio run instructions, an updated wiki status, and a work-log entry with the checks actually completed.
