# Saathi

Saathi is an Android prototype for elder check-ins and guardian follow-up. It uses Flutter and Dart with a small Kotlin bridge for Android settings and notifications.

## Contents

- [What works](#what-works)
- [Setup](#setup)
- [Try the demo](#try-the-demo)
- [Development](#development)
- [Roadmap](#roadmap)
- [License](#license)

## What works

- **Elder mode** offers a time-of-day greeting, compact wellness overview, and a two-column action pad that scrolls vertically.
- **Guardian mode** offers fictional profiles, six synthetic readings, and a timestamped alert history. Demo scenarios include typical readings, high blood pressure, low oxygen, and missing data.
- **Android controls** include a first-launch notification permission request and settings links in both modes. Demo alerts create local Android notifications.
- **Voice draft** transcribes speech or accepts typed text, reads the draft aloud, and sends it to an accepted Saathi guardian through the app backend when configured.
- **Languages** include English, Tamil, Kannada, Telugu, and Malayalam for the mode picker, elder interface, and language selection. Guardian dashboard and Android demo notification copy currently use English.

## Setup

Install Flutter, Android Studio, and the Android SDK. Start an emulator or connect a device running **Android 13 (API 33)** or later.

```sh
git clone https://github.com/teem-vortex/saathi.git
cd saathi
flutter doctor
flutter pub get
flutter run
```

## Try the demo

1. Allow notifications if you want to see the Android demo alert.
2. Open **Guardian mode → Meera** and choose **High BP test** or **Low oxygen test**.
3. Open **Alerts** to see the simulated reading and its recorded time.
4. Return to the mode picker and open **Elder mode** to see Meera’s corresponding summary and warning icon. Use **Typical** in Meera’s guardian profile to restore the default demo state.

The readings and alert rules are for demonstration. Cross-device messaging requires the Supabase migration and authenticated users.

## Development

The in-app messaging MVP requires a Supabase project with the migration in
`supabase/migrations` applied. Supply `SUPABASE_URL` and `SUPABASE_ANON_KEY`
as Flutter `--dart-define` values. Use only a Supabase publishable/anon key in
the app, never the service-role key. Each user creates an email account. The
guardian creates a code, the elder enters it, and the guardian accepts the
request before a message can be sent. Refresh the Messages screen to see updates.

Android push additionally requires Firebase project configuration through the
`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, and
`FIREBASE_PROJECT_ID` Flutter defines. Deploy `supabase/functions/notify-message`
and configure its `FIREBASE_SERVICE_ACCOUNT` secret in the trusted Supabase
environment. Never place a Firebase service account in the app or repository.
This integration is unverified until a configured project and two devices are
available. Push is currently requested by the sending client after the message
is saved, so interruption between those steps can leave a message without a
notification. The recipient can still refresh Messages.

For a local Android build, download `google-services.json` for package
`com.example.saathi` from Firebase and place it at `android/app/google-services.json`.
The file is ignored by Git. Then set the Supabase publishable key and run:

```powershell
$env:SUPABASE_ANON_KEY = '<your Supabase publishable/anon key>'
.\tool\build_mvp.ps1
```

The Firebase project supplies push delivery only. Supabase remains the account,
pairing, message, and token database for this MVP.

```sh
dart format lib test
flutter analyze
flutter test
```

The [AI Wiki](AI-Wiki/Home.md) contains the design, UI requirements, decisions, and work log. See [AGENTS.md](AGENTS.md) for repository guidance.

## Roadmap

- Approved elder–guardian pairing and cross-device delivery
- Health Connect imports, starting with synthetic data for testing
- Localized AI summaries using approved readings and the selected app language
- Background monitoring and restart recovery

## License

Saathi is distributed under the [GNU General Public License v3.0](LICENSE).

### Google sign-in setup

Saathi uses Supabase OAuth with a browser and an Android app callback. Configure
Google Auth Platform with an OAuth **Web application** client. Add the Supabase
Google provider callback URL shown in the Supabase dashboard as an authorized
redirect URI in Google Cloud, and enter the web client ID and secret in the
Supabase Google provider settings. Configure the Google consent screen and add
test users while the app is in testing. In Supabase Authentication URL
Configuration, allow `com.teemvortex.saathi://login-callback/` as a redirect
URL. Supply `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the Flutter build as
above; never put the Google client secret in the app. Google OAuth and the
Android callback must be tested with the configured project and a real account.
