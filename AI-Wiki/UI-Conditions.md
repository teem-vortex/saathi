# UI Conditions

## Mode selection

- Offer **Elder mode** and **Guardian mode** on the opening screen. During the UI preview, tapping a mode opens it directly.
- Keep a visible **Switch mode** control and standard Android back navigation on both mode screens.

## Elder mode

- Keep the home screen simple and touch-first. Use large, clearly labeled actions, generous spacing, and readable contrast.
- The preview has **Talk to Saathi**, **Hear messages**, **I’m okay**, and **Ask for a call**. Keep these actions readable with large text and usable with Android accessibility services.
- When callback or sharing is implemented, show who receives it, request confirmation, and give feedback that reflects the actual result. Keep a touch path alongside voice controls.

## Guardian mode

- Make it a dashboard for connected family and recent updates. Use an honest empty state before there is data, and label any demo data.
- When live events are added, show status, time, and the relevant action. Distinguish a missed check-in from a delayed sync.

## Preview feedback

- Indicate when an action is still a preview. A preview tap should never claim a call, message, or check-in was sent.

## Language and layout update — 2026-11-22

- Elder actions use a vertically scrollable pad with two columns and expandable rows. Each action has an icon and text. Keep settings accessible at the top right.
- Offer English, Tamil, Kannada, Telugu, and Malayalam in settings accessible from both modes. Apply the selected language across the app and retain the choice on the device.
- The Guardian interface should remain straightforward while allowing a richer dashboard suited to managing multiple people.

- Place a compact, localized time-of-day greeting and readings summary above the Elder action pad. Use checks for in-range demo readings, a red warning triangle for a flagged reading, and a dash for unavailable data.
