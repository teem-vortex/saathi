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
