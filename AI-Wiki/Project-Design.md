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
4. Add voice controls and an optional Android assistant shortcut. Verify offline retries, revocation, and voice behavior on supported devices.

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
