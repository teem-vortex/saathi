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

The readings and alert rules are for demonstration. Elder action buttons are previews.

## Development

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
