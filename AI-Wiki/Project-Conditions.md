# Project Conditions

- **Platform.** Build one Flutter and Dart Android app with Elder and Guardian modes. Preserve Android 13 (API 33) as the minimum in `android/app/build.gradle.kts` until the team changes the target. Use Kotlin for Android-specific integrations when needed.
- **Phase boundaries.** During the UI preview, both modes open directly. Authentication, phone verification, pairing, backend calls, and sensor collection are later work.
- **Data and access.** Ask the elder before sharing personal updates, show the recipient and what will be shared, and make sharing revocable. Use fictional data for local demos. Keep private information and credentials out of the repository, wiki, logs, and sample files.
- **Verification.** Report static analysis, test results, emulator checks, and live service validation according to what actually ran. The baseline development device is a Pixel 7 Android 13 Google Play emulator.
- **Repository.** Track the AI wiki and skill in Git. Preserve unrelated work. Ask for explicit authorization before committing, pushing, or deploying.
- **Standing feedback.** Approved ongoing project instructions belong in this note or [UI Conditions](UI-Conditions.md). Preserve their scope. Record the date and reason for changes in [Decisions](Decisions.md) or the [Work Log](Work-Log.md).
