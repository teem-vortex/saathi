# UI Conditions

## Mode selection

- Offer **Elder mode** and **Guardian mode** on the opening screen. During the UI preview, tapping a mode opens it directly.
- Keep a visible **Switch mode** control and standard Android back navigation when the app is opened normally. When opened as the Home launcher, show the Elder screen without a back or mode-switch control.

## Elder mode

- Keep the home screen simple and touch-first. Use large, clearly labeled actions, generous spacing, and readable contrast.
- The preview has **Talk to Saathi** and **Hear messages**. Keep these actions readable with large text and usable with Android accessibility services.
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

- Give Android Home its own Flutter launcher screen. Keep the Android status bar visible and show the system wallpaper around the launcher cards and tiles.
- Place one wide greeting and readings card above the existing two-column Elder action grid. Keep the settings gear and the controls to change the Home app. The launcher root has no app Back or mode-switch control.
- Offer **Minimal** with the existing Elder actions and optional direct app tiles. **Normal** also provides an **Apps** tile. Let users show all launchable apps or a preferred subset. The app menu scrolls vertically with two columns for up to 10 visible apps and three for 11 or more.
- Show Launcher type as a Minimal / Normal (with app menu) dropdown. Grey launcher customization until Android reports Saathi as the Home app. Tapping a grey option explains how to enable Saathi, scrolls to the Home selection control, and highlights it. Keep the Home selection control available at all times.
- Show the system wallpaper through the Apps menu background and keep its back arrow visible.

## Theme

- Offer **Use system theme**, **Dark**, and **Light** under **Theme** in Elder and Guardian Settings and through the launcher gear. Use system theme by default. Share the saved choice across Elder, Guardian, and both launcher layouts.
- Keep text, action icons, and reading states readable in both themes. Keep Android wallpaper visible around the launcher and Apps menu tiles, with readable system bars and Back controls.
- Put Saathi Connections in Elder and Guardian Settings. The launcher Settings opens Elder Connections.
- Offer a default-on Call tile in both Elder launcher layouts, controlled through User extras. The Call screen shows chosen phone contacts in two columns and keeps Add contact in the three-dot menu.

## Watch Elder interface — 2026-11-24

- Use the selected teal and ivory watch concept with a localized time-of-day greeting and compact status above a vertically scrolling, two-column action grid. Rows near the display center grow while rows near the curved edges shrink smoothly. Keep actions labeled and Settings accessible. A future summary will use real readings and the selected language.
- Start centering the nearest watch action row as soon as the finger lifts. Use release momentum for quick swipes and ease into the final position. Preserve access to the greeting at the top, and allow the final row to reach the center.
- Keep watch rows face-on throughout the scroll. Scale width and height uniformly toward the edges, and use the original side spacing.
