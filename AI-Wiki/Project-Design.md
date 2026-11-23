# Project Design

Saathi helps older adults send check-ins and ask family for a callback while controlling what they share. The Guardian mode gives approved family members a place to see updates and respond.

## Delivery status

- The published baseline is a Flutter Android starter app with `minSdk = 33`.
- At wiki creation, a mode picker, Elder home, and Guardian dashboard were implemented and verified in the local working tree. Check the current branch for availability. The Elder actions show a preview message and the Guardian dashboard shows an empty state.
- Phone verification, family pairing, live device-to-device communication, AWS, push notifications, and voice integration are planned.

## Planned sequence

1. Refine the role picker, Elder home, Guardian dashboard, and callback confirmation. Walk through a mock callback before integrating services.
2. Set up Cognito for authentication and DynamoDB for storage. Add Lambda handlers behind API Gateway. Connect the Flutter screens and verify approved pairing and the callback flow on two devices.
3. Add check-ins and family messages. Add Firebase Cloud Messaging with generic notification text and fetch sensitive details through the authenticated app.
4. Add voice controls and optional default Android assistant support. See the [Elder phone assistant plan](#elder-phone-assistant-plan).

## Callback flow

The elder chooses an approved recipient and confirms the request. The app shows whether the request is pending or sent. The family member opens the authorized request and can follow up. The backend checks the user's connection and permissions before returning an event.

See [Project Conditions](Project-Conditions.md) for sharing rules and [UI Conditions](UI-Conditions.md) for screen requirements.

## Care-home goal — 2026-11-22

Support an old-age home with many elders and one or more guardians. Guardians should be able to browse a list of people, open an individual record for details, monitor updates, and send a check-in or notification. This care-home workflow is a future goal. It does not require phone-call functionality for the care-home use case. Relationships, consent, access control, and actual monitoring need design and implementation.


## Android wearable integration plan

Saathi will use one read-only Health Connect integration on the elder’s Android phone. The path is **watch → brand’s companion app → Health Connect → Saathi**. Each companion app must export the records Saathi needs, and the elder grants Saathi read access for those data types. A dedicated brand integration is a follow-up option for a required device or metric that the shared path cannot provide.

1. Start with labeled synthetic step counts and timestamps to test the phone UI, including missing and stale readings.
2. Seed synthetic records with Health Connect Toolbox on an Android test device to verify Saathi’s permission flow and actual reads. Health Connect is a separate app on Android 13 and built into Android 14 and newer. [Android availability](https://developer.android.com/health-and-fitness/health-connect/availability) · [Health Connect Toolbox](https://developer.android.com/health-and-fitness/health-connect/test/health-connect-toolbox)
3. Later, verify exported metrics and sync freshness end to end with physical watches. The integration and test sequence are planned.

For a Galaxy Watch, the phone integration can read approved records through Galaxy Watch → Samsung Health on the paired Android phone → Health Connect → Saathi. This path uses the existing watch software and imports synced data on Samsung's schedule. Verify available fields and sync freshness on the actual model before relying on them. Keep readings local unless the elder chooses an update to share. [Samsung Health Connect FAQ](https://developer.samsung.com/health/health-connect-faq.html)

A Saathi Wear OS companion is an option for on-watch actions or measurements. It can read supported signals through Wear OS Health Services and exchange data with the paired Saathi phone app through the Wear OS Data Layer. A Wear OS emulator can test the companion UI and synthetic measurements. Actual sensors, pairing with the intended watch, and sync behavior require hardware verification. Samsung's separate Health Sensor SDK requires a compatible Galaxy Watch4 or newer and lacks emulator support. [Wear OS Data Layer](https://developer.android.com/training/wearables/data/overview) · [Simulated data](https://developer.android.com/health-and-fitness/health-services/simulated-data) · [Samsung Sensor SDK](https://developer.samsung.com/health/sensor/overview.html)

### Other Android-compatible wearables

A watch can work with an Android phone without running Wear OS. For synced activity imports, prefer one phone-side Health Connect reader. Verify which records the companion app writes, their origin and timestamp, and the phone OS and region. In particular, Garmin's export requires Android 14 or newer even though Saathi supports Android 13.

- Google Pixel Watch and Fitbit sync through the Google Health app, which documents data it writes to Health Connect. [Google Health](https://support.google.com/googlehealth/answer/14506680)
- Garmin Connect exports steps, heart rate, and sleep stages on Android 14+. Garmin also has a separate developer Health API. [Garmin Connect export](https://support.garmin.com/en-IN/?faq=JToBEy0jfe6pIygark2Ui5) · [Garmin Health API](https://developer.garmin.com/gc-developer-program/enterprise/health-api/)
- Xiaomi and Redmi devices that use Mi Fitness can use its Health Connect sync. OnePlus documents OHealth's move to Health Connect. Check the exact model and available metrics. [Mi Fitness](https://play.google.com/store/apps/details?id=com.xiaomi.wearable) · [OnePlus OHealth update](https://community.oneplus.com/thread/1595284620985761795)
- Huawei offers a separate authorized Health Kit integration. Amazfit's India Zepp FAQ lists services such as Google Fit and Strava. Direct Health Connect export from Zepp needs verification on the target app and device before promising support. [Huawei Health Kit](https://developer.huawei.com/consumer/en/hms/huaweihealth/) · [Amazfit Zepp FAQ](https://in.amazfit.com/pages/faq/what-apps-can-the-zepp-app-sync-with)

A custom watch app remains an option for compatible Wear OS models. Consider a vendor API only when it covers a needed device or metric. Direct Bluetooth is an option only where the device exposes a supported sensor profile or integration protocol.

## Proposed guardian dashboard and synthetic alert demo

The requested next phase is a local dashboard and alert prototype. Use clearly labeled fictional people and measurements, including blood pressure, oxygen saturation, heart rate, temperature, and activity where sample data exists. Each entry needs a unit, measurement time, source, and an unavailable or stale state. Guardian can open a person and inspect current measurements and an alert history.

Provide deterministic normal, high, low, and missing-data test scenarios. A shared evaluation path creates a timestamped local alert and a generic Android notification for designated test values. Explicitly label the scenarios and thresholds as demo-only. Real clinical interpretation, source validation, and individualized thresholds need separate design and clinical review.

On first use, explain and request notification permission. Both modes' settings should display notification and battery-optimization status and link to Android settings so users can change them. Investigate background work and reboot recovery against current Android restrictions and verify on the target device. User-approved optimization exemptions do not guarantee continuous execution. AWS, Lambda, FCM, remote delivery, and Health Connect remain separate later integrations; local notification testing cannot establish remote push delivery.

### Elder summary demo

The Elder overview uses the fictional Meera profile and the latest scenario selected for her in Guardian mode. The overview shows a deterministic summary. Its request carries the selected app language code and flagged metrics so a future AI provider can produce a short localized summary from the same facts. The current version requires no network or API credentials.

## Elder Home launcher redesign plan

Saathi remains one Android app with an optional Home role. Android Home will use a dedicated Flutter screen so the launcher can evolve independently of the in-app Elder UI.

1. **Separate the screens.** Route the existing HomeActivity and /elderHome entry to a dedicated launcher screen in its own Dart file. Move launcher layout and navigation out of ModePage. Share saved language, greeting and readings data, shared Settings, and action handlers where behavior is common.
2. **Show the actual Android wallpaper.** Give HomeActivity its own launch and normal themes with a transparent background and Android's windowShowWallpaper. Use Flutter's transparent activity mode and keep the Flutter launcher root and scroll area transparent. Check for solid background flashes on cold launch and return to Home. [Android wallpaper windows](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#FLAG_SHOW_WALLPAPER) · [Flutter transparent activities](https://docs.flutter.dev/add-to-app/android/add-flutter-screen)
3. **Keep the real system bars visible.** Use edge-to-edge layout with the system bars shown. Let wallpaper extend behind them and use safe insets to place controls below the status bar, away from cutouts and above the navigation controls. If needed, add a subtle gradient only behind the status icons for contrast. Verify the clock, battery and network icons, notification shade, and gesture and three-button navigation. [Android edge-to-edge](https://developer.android.com/develop/ui/views/layout/edge-to-edge)
4. **Build the launcher layout.** Place the settings gear at the top right below the system status bar. Follow it with one wide card containing the time-of-day greeting, name, short summary, and compact reading indicators. Put the four existing icon-and-text action tiles below it in two columns and vertically scrolling rows. Give cards and tiles readable surfaces and leave the gaps and margins transparent. Allow longer translations and larger text to wrap. The launcher root has no app bar, Back button, or mode switch.
5. **Verify navigation and recovery.** Pressing Home from another app or a nested screen returns to the launcher root. Closing Settings or Talk to Saathi returns to the launcher. The regular Saathi icon opens the mode picker. Keep Change Home app accessible through Settings and refresh the saved language and greeting when returning to Home.

Start with Flutter analysis and tests, then verify the Home role on the Pixel 7 Android 13 emulator. Select Saathi in Android, check bright, dark, and busy wallpapers and a live wallpaper if available, and change wallpaper while Saathi is Home. Test larger text, the five languages, safe insets, and access to all tiles. Check rotation, process restart, reboot, and switching back to Pixel Launcher. Repeat the visual and navigation checks on a newer Android image and on a Samsung device when available, including restoring One UI Home.

The dedicated launcher, wallpaper, status bar, card, and grid are implemented locally. The Pixel 7 Android 13 emulator showed the wallpaper and system bars, opened Settings, and returned to the launcher root on Home. Broader wallpaper, accessibility, reboot, and Samsung checks are pending.

### Launcher layouts and app shortcuts

1. **Add a layout setting.** The launcher gear offers **Minimal** and **Normal**. Default existing installs to Minimal, with the greeting card and four Elder actions. Normal adds an **Apps** tile and any pinned shortcuts. Save the layout, menu filter, and pinned apps locally so they survive restarts and switching modes.
2. **Reuse the app bridge.** Build on the existing Android LauncherApps calls and Flutter installed-app list. Display launchable apps alphabetically with their icons and names. Store choices by package and activity. Refresh on return to Home and when opening the menu or picker. Omit uninstalled apps from the visible grid and handle an app disappearing before launch.
3. **Build the app menu and picker.** In Normal settings, **Choose app menu apps** offers **All apps** and **Selected apps**. Default the menu to All apps, which includes newly installed apps automatically. Selected apps uses a checklist and Save button. The Apps tile opens a vertically scrolling grid with two columns for up to 10 visible apps and three for 11 or more. An empty selection offers a way back to the picker.
4. **Add direct app tiles.** In Normal settings, **Add app as tile** opens the app picker. Pinned apps appear in the two-column Home grid and open directly. The same setting lets the user remove shortcuts. Home shortcuts and app menu visibility are separate choices.
5. **Verify on Android 13.** Test switching layouts, persistence after restart, All apps, a saved subset, and an empty result. Check the grid at 9, 10, and 11 apps. Open an app from the menu and from a pinned tile, then press Home to return. Check the five supported languages and larger text. Both layouts keep the status bar, wallpaper, and existing Elder actions.

The layout selector, app menu, app picker, and pinned tiles are implemented locally. The Pixel API 33 emulator verified switching to Normal and opening the app menu. Translations and the 10/11-app boundary require further verification.

## Elder phone assistant plan

**User flow.** Elder Settings offers **Use Saathi as phone assistant** and shows whether Saathi is selected. The button opens Android's Default apps settings so the user can choose Saathi under the digital assistant setting. **Change phone assistant** opens the same settings to switch back. Refresh the status from Android when Elder Settings resumes. Provide manual steps if the settings screen cannot be opened. The assistant and Home roles are independent.

1. **Register a dedicated assistant entry in Kotlin.** Start with an activity that handles `ACTION_ASSIST` and opens directly to a shared Elder voice screen. Verify the real system shortcut on the API 33 Pixel emulator and a Samsung phone. If the activity route fails to receive a supported shortcut on a target phone, evaluate `VoiceInteractionService` and `VoiceInteractionSessionService` before settling on the entry point. Keep assistant invocation separate from the normal app and Home entry points. [Android assistant role](https://developer.android.com/reference/androidx/core/role/RoleManagerCompat#ROLE_ASSISTANT) · [VoiceInteractionService](https://developer.android.com/reference/android/service/voice/VoiceInteractionService)
2. **Reuse the voice screen.** Route both **Talk to Saathi** and the Android shortcut to the same Flutter UI. Use the saved Elder language and large controls. Show connecting, listening, speaking, and unavailable states with text and a simple mic animation. Provide a prominent **Stop** control. Closing the session should return the user to the previous screen and release the microphone. Coalesce repeated invocations into one session.
3. **Connect ElevenLabs when the voice backend is ready.** Use the Kotlin SDK through the existing Flutter-to-Android bridge. Request microphone permission when the user starts voice, use a short-lived token from the backend, and keep the API key on the server. Test first with synthetic summaries. Require unlocking before opening a voice session from the lock screen. Keep requests that share data or send callbacks behind the existing confirmation and authorization rules. Always-listening wake words are a separate follow-up. [ElevenLabs Android SDK](https://elevenlabs.io/docs/eleven-agents/libraries/kotlin)
4. **Verify both roles.** On the Pixel API 33 emulator, test selecting and canceling in Android settings, system invocation from another app, stopping, external changes to the default, and switching back. Check behavior when the microphone is denied, the device is locked, the network is offline, or the process restarts. Repeat shortcut and switch-back checks on a physical Samsung phone because the assigned gesture or button depends on the device. Verify Saathi works both with and without its Elder launcher selected. Use a physical device to confirm audio and language behavior.

Status: assistant activity, Elder Settings control, and a shared unavailable voice screen are implemented locally. ElevenLabs voice, translated labels, system shortcut selection, lock-screen behavior, and Samsung verification remain pending. The Android 13 emulator resolved and explicitly launched the assistant activity.
