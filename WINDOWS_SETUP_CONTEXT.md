# Saathi Windows 11 setup for an AI coding agent

## Teammate instructions

1. Give this entire Markdown file to your coding agent on your **Windows 11 PC**. Use an agent with access to local PowerShell and your filesystem. If it can also operate your Windows desktop, give it access so it can do the Android Studio clicks.
2. Send it this message: **“Follow this file on my Windows 11 machine. Check what is already installed, install what is missing, clone Saathi, and leave the starter app running on my emulator. Take over whenever your tools allow. Show me exactly what to click only when you need my input.”**
3. Stay available for Windows administrator prompts, license decisions, and a possible restart. If the agent hands a step to you, finish that step and tell it what you see so it can resume. Enter any credentials directly in the official sign-in window.
4. The setup is done when the Flutter starter counter is visible on the Android 13 emulator, the **+** button increments it, and the agent tells you where to open the cloned project in Android Studio.

## Agent instructions

Own this setup through the running app. Inspect the actual Windows host, perform the steps you have tools and permission for, then verify each result. Use OS and SDK commands where practical and desktop automation for supported installer and Studio dialogs. Ask the teammate to handle a step only if you cannot operate that interface, the step requires their decision or approval, or the machine needs a restart. Give them the exact button, expected screen, and what to report so you can resume. If you only have a remote or Linux shell, explain that limitation and have the teammate run the Windows-specific steps locally. Never report an installation or app launch you did not verify.

Use the existing project and keep setup local. Do not create a new Flutter app, change tracked application code or dependencies, begin feature implementation, commit, push, or configure a backend. Reuse working installations and an existing correct clone. Do not overwrite teammate work in an existing checkout.

## Project and toolchain

| Item | Value |
|---|---|
| GitHub repository | [teem-vortex/saathi](https://github.com/teem-vortex/saathi) |
| Clone URL | `https://github.com/teem-vortex/saathi.git` |
| Default branch | `main` |
| Initial starter baseline | `3d556a08f288aa1f974b0f03493d2a6c43549792` |
| Stack | Flutter and Dart, with Kotlin for the Android host |
| Known working Flutter version | Flutter **3.50.1 stable**, bundled Dart **3.14.0** |
| Android compile and target SDK at this baseline | API **36** |
| Minimum Android version | Android **13**, API **33**, already set in `android/app/build.gradle.kts` |
| Emulator | **Pixel 7**, Android **13 / API 33**, **Google Play**, **x86_64** |
| App ID and entry point | `com.example.saathi`, `lib/main.dart` |

The starter was verified on an Android 13 Pixel 7 emulator on Fedora. Validate the full flow on the teammate's Windows machine. Install Android SDK **Platform 36** for compilation and the **API 33 emulator system image** for testing. Flutter comes with Dart. Android Studio comes with a Java runtime. For this Android workflow, Chrome and Microsoft Visual Studio are optional.

## 1. Install Android Studio and Git

- Open native Windows PowerShell and check the OS and CPU architecture. Use this emulator profile on x64 Windows. If the machine is ARM64, check current official Android Studio support before downloading anything. If unsupported, report that and coordinate a supported x64 machine.
- Check whether Android Studio and Git already work. Locate `studio64.exe` and its adjacent `jbr` directory. The default installation is usually `C:\Program Files\Android\Android Studio`. Run `git --version` and check for an existing Android SDK and Flutter SDK.
- Install stable Android Studio if missing. Prefer the official [Android Studio Windows installer](https://developer.android.com/studio). If WinGet is available, the agent can first verify the package with `winget show --id Google.AndroidStudio --exact --source winget`, then run `winget install --id Google.AndroidStudio --exact --source winget`. Otherwise open the official download page, download the Windows x64 installer, and launch it. Ask the teammate to review and accept any download terms or approve the installer on the Windows UAC screen themselves. See the [official installation instructions](https://developer.android.com/studio/install).
- Install Git for Windows if missing. With WinGet, verify with `winget show --id Git.Git --exact --source winget`, then run `winget install --id Git.Git --exact --source winget`. The official [Git for Windows download](https://git-scm.com/download/win) is the fallback. Refresh the terminal or use the installed Git executable by absolute path, then verify `git --version`.

## 2. Finish Studio's first run and enable Flutter support

Use desktop automation if available. If the agent cannot control Studio, have the teammate follow these steps and tell the agent once the welcome screen reappears after the restart.

1. Open **Start → Android Studio**. If asked about importing settings, keep existing settings if appropriate or choose **Do not import settings** for a fresh installation.
2. Advance through the setup wizard. **Standard** is fine for a default install. If choosing **Custom**, keep an existing valid SDK or use the default user location, usually `%LOCALAPPDATA%\Android\Sdk`. Note this folder. Review SDK licenses when prompted, approve them if you agree, and let the download finish. Click **Finish**.
3. On the welcome screen, open **Plugins → Marketplace**. If a project opens, use **File → Settings → Plugins → Marketplace**. Search for **Flutter**, install the official Flutter plugin, and allow installation of its **Dart** dependency. Check **Installed** for both plugins. If Dart was not installed, install it from Marketplace. Restart Studio.
4. Leave Studio at the welcome screen. The agent will open the cloned **Saathi project root** when it is ready. [Flutter support in Android Studio](https://docs.flutter.dev/tools/android-studio)

## 3. Install the Flutter SDK and configure its paths

The agent should execute this section. While Studio's first-run wizard is waiting for a person, the agent can install Flutter or clone the repository independently.

- Use the [official Flutter SDK archive](https://docs.flutter.dev/install/archive), choose Windows x64, and install **3.50.1 stable** for the starter baseline. Reuse the compatible SDK if present. If an existing SDK serves other projects and is a different version, install the baseline alongside it. If the repository has moved past the starter, inspect its SDK constraints and setup instructions before choosing a version. The baseline uses Dart 3.14.0.
- Download the official ZIP and extract it to a user-writable, local directory such as `%USERPROFILE%\development`, giving `%USERPROFILE%\development\flutter\bin\flutter.bat`. A short writable path is preferable, especially if the user's home folder contains spaces or is synced. Keep the SDK outside the repository and avoid overwriting an existing SDK.
- Add the chosen SDK's `bin` directory to the **user** PATH if needed and refresh the current process PATH or call `flutter.bat` by absolute path. Keep other PATH entries. When multiple Flutter SDKs exist, explicitly use the chosen one in the terminal and in Studio.
- In PowerShell, use the verified paths below. Change the defaults if discovery found a different location.

```powershell
$FlutterRoot = Join-Path $env:USERPROFILE 'development\flutter'
$Flutter = Join-Path $FlutterRoot 'bin\flutter.bat'
$SdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$StudioRoot = Join-Path $env:ProgramFiles 'Android\Android Studio'

& $Flutter --version
& (Join-Path $FlutterRoot 'bin\dart.bat') --version
& $Flutter config --android-sdk $SdkRoot
& $Flutter doctor -v
```

If Flutter cannot find Android Studio, run `& $Flutter config --android-studio-dir $StudioRoot`. If it cannot find compatible Java or selects a conflicting JDK, inspect the Gradle/JDK compatibility message and use the working Studio JBR with `& $Flutter config --jdk-dir (Join-Path $StudioRoot 'jbr')` when appropriate. SDK management tools launched directly may need `$env:JAVA_HOME = Join-Path $StudioRoot 'jbr'` in the current shell. [Flutter manual installation](https://docs.flutter.dev/install/manual) · [Java and Android builds](https://developer.android.com/build/jdks)

## 4. Install Android SDK components and check acceleration

- Open **More Actions → SDK Manager** from Studio's welcome screen, or **Tools → SDK Manager** from a project. Confirm the SDK location agrees with `$SdkRoot`. In **SDK Platforms**, select **Android 16 / API 36**. In **SDK Tools**, select **Android SDK Platform-Tools**, **Android SDK Build-Tools**, **Android SDK Command-line Tools (latest)** and **Android Emulator**. Under **Show Package Details**, the starter uses **NDK (Side by side) 28.2.13676358**. Flutter's Android setup also lists **CMake**. Install it through SDK Manager. Click **Apply → OK**. The teammate reviews license prompts.
- If you can work through PowerShell and `sdkmanager.bat` exists, install missing packages there. Inspect installed and available package versions with `--list` first. These are the baseline package IDs. Select an available CMake revision if still needed. Review any build-specific SDK requests that Gradle prints on first run.

```powershell
$SdkManager = Join-Path $SdkRoot 'cmdline-tools\latest\bin\sdkmanager.bat'
& $SdkManager "--sdk_root=$SdkRoot" --list
& $SdkManager "--sdk_root=$SdkRoot" 'platform-tools' 'platforms;android-36' 'build-tools;36.1.0' 'emulator' 'ndk;28.2.13676358' 'system-images;android-33;google_apis_playstore;x86_64'
& $Flutter doctor --android-licenses
& $Flutter doctor -v
```

- If command-line tools are missing, install them through SDK Manager before retrying the commands. If licenses need acceptance, let the teammate review and respond in the dialog or terminal. Verify the Android toolchain and accepted licenses in `flutter doctor -v`. Warnings for unrelated platforms can be left alone. [Flutter Android toolchain](https://docs.flutter.dev/platform-integration/android/setup)
- Check acceleration with `& (Join-Path $SdkRoot 'emulator\emulator.exe') -accel-check`. Reuse working acceleration. When Windows Hypervisor Platform is needed, check feature status first. With approval and available elevation, enable it through Windows Features or the documented equivalent. The human fallback is **Start → Turn Windows features on or off → Windows Hypervisor Platform → OK**, then save work and restart if prompted. If Task Manager's **Performance → CPU** reports virtualization disabled, the teammate may need to enable **Intel VT-x** or **AMD SVM** in firmware. Ask for that only when needed and recheck acceleration after reboot. [Android emulator acceleration on Windows](https://developer.android.com/studio/run/emulator-acceleration)

## 5. Clone the project and boot the emulator

1. Use a writable local workspace. Reuse a correct clone if it exists. If the destination contains unrelated files or uncommitted changes, inspect it and preserve them. The example below is for a new clone.

   ```powershell
   $WorkRoot = Join-Path $env:USERPROFILE 'source'
   $Repo = Join-Path $WorkRoot 'saathi'
   New-Item -ItemType Directory -Force -Path $WorkRoot | Out-Null
   git clone https://github.com/teem-vortex/saathi.git $Repo
   Set-Location $Repo
   git remote -v
   git status --short --branch
   git log -1 --oneline
   ```

   The repository was public at the starter baseline. If access now requires sign-in, use the teammate's GitHub account through the official browser or Git Credential Manager flow. The teammate enters credentials and completes MFA directly. Check repo access with the organization if authentication succeeds and GitHub still denies it.
2. Start a compatible API 33 Google Play AVD if one already exists. Otherwise open **More Actions → Virtual Device Manager** at the welcome screen, or **Tools → Device Manager** within a project. Choose **+ → Create Virtual Device → Phone → Pixel 7**. Pick **Android 13 (Tiramisu), API 33, Google Play, x86_64**, download if prompted, name it **Saathi Pixel 7 API 33**, leave graphics on **Automatic**, and select **Finish**. A Pixel 6 profile with the same image is an acceptable fallback.
3. Use desktop automation or the installed Android AVD tools. If using `avdmanager.bat`, run `list device` and use the actual Pixel 7 device ID with `create avd -n Saathi_Pixel_7_API_33 -k "system-images;android-33;google_apis_playstore;x86_64" -d <device-id>`. Keep default hardware settings. If CLI creation is unavailable, use the Studio path above and ask the teammate to click through only if needed.
4. Boot the device with its **▶** button or by starting the SDK emulator executable with the exact name from `emulator.exe -list-avds`. Wait until Android is at the home screen. Verify with the SDK copy of ADB and Flutter.

   ```powershell
   $Adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
   & $Adb devices -l
   & $Flutter devices
   # Substitute the actual emulator serial if it differs.
   & $Adb -s emulator-5554 shell getprop sys.boot_completed
   & $Adb -s emulator-5554 shell getprop ro.build.version.sdk
   ```

   Expect boot status `1` and SDK `33`. If it goes offline, wait for boot, confirm which ADB is on PATH with `where.exe adb`, use the SDK ADB explicitly, and try **Cold Boot Now** if needed. ADB server resets affect other attached debug sessions. [Android Device Manager](https://developer.android.com/studio/run/managing-avds)

## 6. Open and run the cloned starter app

1. Open the cloned folder that contains `pubspec.yaml` with **Android Studio → Open**. If Studio asks to trust the project, let the teammate decide after verifying the repository and folder. If Flutter SDK configuration is needed, go to **File → Settings → Languages & Frameworks → Flutter** and enter the SDK root. If Dart support is missing, check the Dart plugin and choose the SDK bundled under `flutter\bin\cache\dart-sdk` if Studio asks.
2. From the clone root, run the commands below using the actual serial from `flutter devices`. First build downloads are expected. The project ignores generated Gradle wrapper files and `android/local.properties`. Flutter's Android build generates what it needs, so begin with `flutter run` from the root.

   ```powershell
   Set-Location $Repo
   & $Flutter pub get
   & $Flutter run -d emulator-5554 --no-resident
   ```

   If Studio's Run action is used instead, open `lib/main.dart`, select the running **Saathi Pixel 7 API 33** device and click the green **Run** button. When dependency resolution fails, inspect the first actionable error and fix the local SDK, license, Java, or network problem before retrying. Preserve the tracked lockfile and Gradle configuration. If the project source is at fault, report it with the commit ID and error.
3. Verify installation and launch. `& $Adb -s emulator-5554 shell dumpsys activity activities` should show `com.example.saathi/.MainActivity` as the resumed activity. If you have desktop control, confirm the Flutter starter counter is visible, tap **+** once, and verify the counter increments. If unavailable, ask the teammate to do that visual check and report the result. Leave the app displayed on the emulator.
4. The starter requires no microphone, notification, contacts, or other runtime permission setup. Handle system or tool permissions only as required for installation and debugging. For a physical Android 13+ fallback, the teammate enables **Developer options → USB debugging**, connects a data cable, and approves the phone's USB debugging prompt. Check `flutter devices` and choose that serial. Report it as a physical-device run if the emulator could not be verified.

Finish by giving the teammate the clone path, checked-out branch and commit, Flutter version, device name and API, app launch and counter result, and any unresolved issue. Run `git status --short --branch` and confirm the setup left application source ready for their own changes.
