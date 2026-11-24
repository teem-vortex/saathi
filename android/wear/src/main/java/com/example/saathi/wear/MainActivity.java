package com.example.saathi.wear;

import android.animation.ValueAnimator;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.role.RoleManager;
import android.content.Intent;
import android.content.res.Configuration;
import android.provider.Settings;
import android.content.ActivityNotFoundException;
import android.content.pm.LauncherActivityInfo;
import android.content.pm.LauncherApps;
import android.os.Process;
import java.util.Collections;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.animation.DecelerateInterpolator;
import android.widget.LinearLayout;
import android.widget.ImageView;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

public class MainActivity extends Activity {
    private int BACKGROUND;
    private int INK;
    private int CARD;
    private int foreground;
    private boolean settingsVisible;
    private boolean returningFromSettings;
    private static final String[] LANGUAGES = {"English", "தமிழ்", "ಕನ್ನಡ", "తెలుగు", "മലയാളം"};
    private static final String[][] LABELS = {
        {"Good morning", "Good afternoon", "Good evening", "All is well · Demo", "Talk", "Messages", "I'm okay", "Call", "Settings", "Language", "Theme", "System", "Light", "Dark", "Set Saathi as Home", "Change Home app", "Notifications", "Battery settings", "Back", "Coming soon"},
        {"காலை வணக்கம்", "மதிய வணக்கம்", "மாலை வணக்கம்", "நலம் · மாதிரி", "பேசு", "செய்திகள்", "நலமாக உள்ளேன்", "அழைப்பு", "அமைப்புகள்", "மொழி", "தோற்றம்", "கணினி", "ஒளி", "இருள்", "Saathi முகப்பாக", "முகப்பை மாற்று", "அறிவிப்புகள்", "மின்கல அமைப்புகள்", "பின்", "விரைவில்"},
        {"ಶುಭೋದಯ", "ಶುಭ ಮಧ್ಯಾಹ್ನ", "ಶುಭ ಸಂಜೆ", "ಎಲ್ಲವೂ ಚೆನ್ನಾಗಿದೆ · ಮಾದರಿ", "ಮಾತನಾಡಿ", "ಸಂದೇಶಗಳು", "ನಾನು ಚೆನ್ನಾಗಿದ್ದೇನೆ", "ಕರೆ", "ಸೆಟ್ಟಿಂಗ್‌ಗಳು", "ಭಾಷೆ", "ಥೀಮ್", "ಸಿಸ್ಟಮ್", "ಬೆಳಕು", "ಕತ್ತಲೆ", "Saathi ಮುಖಪುಟ", "ಮುಖಪುಟ ಬದಲಿಸಿ", "ಅಧಿಸೂಚನೆಗಳು", "ಬ್ಯಾಟರಿ ಸೆಟ್ಟಿಂಗ್", "ಹಿಂದೆ", "ಶೀಘ್ರದಲ್ಲೇ"},
        {"శుభోదయం", "శుభ మధ్యాహ్నం", "శుభ సాయంత్రం", "అంతా బాగుంది · నమూనా", "మాట్లాడు", "సందేశాలు", "నేను బాగున్నాను", "కాల్", "సెట్టింగ్‌లు", "భాష", "థీమ్", "సిస్టమ్", "లైట్", "డార్క్", "Saathi హోమ్", "హోమ్ మార్చు", "నోటిఫికేషన్లు", "బ్యాటరీ సెట్టింగ్‌లు", "వెనుకకు", "త్వరలో"},
        {"സുപ്രഭാതം", "ശുഭ മധ്യാഹ്നം", "ശുഭ സായാഹ്നം", "എല്ലാം നന്ന് · മാതൃക", "സംസാരിക്കുക", "സന്ദേശങ്ങൾ", "എനിക്ക് സുഖം", "വിളിക്കുക", "ക്രമീകരണങ്ങൾ", "ഭാഷ", "തീം", "സിസ്റ്റം", "വെളിച്ചം", "ഇരുട്ട്", "Saathi ഹോം", "ഹോം മാറ്റുക", "അറിയിപ്പുകൾ", "ബാറ്ററി ക്രമീകരണം", "തിരികെ", "ഉടൻ വരുന്നു"}
    };

    private android.content.SharedPreferences preferences() {
        return getSharedPreferences("wear_settings", MODE_PRIVATE);
    }

    private String label(int index) {
        int language = preferences().getInt("language", 0);
        return LABELS[Math.max(0, Math.min(language, LABELS.length - 1))][index];
    }
    private final List<View> rows = new ArrayList<>();

    private class SnappingScrollView extends ScrollView {
        private static final int NON_TOUCH_IDLE_MS = 70;
        private static final float FLING_LOOKAHEAD_SECONDS = 0.08f;

        private boolean touching;
        private int releaseVelocity;
        private ValueAnimator settleAnimation;
        private final Runnable settleAfterNonTouchScroll = () -> settle(0);

        SnappingScrollView() {
            super(MainActivity.this);
        }

        private void settle(int velocity) {
            if (!isAttachedToWindow() || rows.isEmpty()) return;
            int center = getHeight() / 2;
            int current = getScrollY();
            // A quick swipe can cross a row boundary through momentum.
            int projected = current + Math.round(velocity * FLING_LOOKAHEAD_SECONDS);
            int target = 0;
            int distance = Math.abs(projected);
            for (View row : rows) {
                int position = Math.max(0, row.getTop() + row.getHeight() / 2 - center);
                int candidateDistance = Math.abs(projected - position);
                if (candidateDistance < distance) {
                    distance = candidateDistance;
                    target = position;
                }
            }
            if (target == current) return;

            float distanceDp = Math.abs(target - current) / getResources().getDisplayMetrics().density;
            settleAnimation = ValueAnimator.ofInt(current, target);
            settleAnimation.setDuration(Math.round(Math.min(260f, 90f + distanceDp * 1.8f)));
            settleAnimation.setInterpolator(new DecelerateInterpolator());
            settleAnimation.addUpdateListener(animation -> scrollTo(0, (int) animation.getAnimatedValue()));
            settleAnimation.start();
        }

        private void stopSettling() {
            removeCallbacks(settleAfterNonTouchScroll);
            if (settleAnimation != null) settleAnimation.cancel();
        }

        @Override
        public void fling(int velocityY) {
            // Use the release velocity to choose the row as part of the same animation.
            releaseVelocity = velocityY;
        }

        @Override
        public boolean dispatchTouchEvent(MotionEvent event) {
            int action = event.getActionMasked();
            if (action == MotionEvent.ACTION_DOWN) {
                touching = true;
                releaseVelocity = 0;
                stopSettling();
            }
            boolean handled = super.dispatchTouchEvent(event);
            if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
                touching = false;
                settle(releaseVelocity);
            }
            return handled;
        }

        @Override
        public boolean onGenericMotionEvent(MotionEvent event) {
            if (event.getActionMasked() == MotionEvent.ACTION_SCROLL && !touching
                    && settleAnimation != null) {
                settleAnimation.cancel();
            }
            return super.onGenericMotionEvent(event);
        }

        @Override
        protected void onScrollChanged(int x, int y, int oldX, int oldY) {
            super.onScrollChanged(x, y, oldX, oldY);
            if (!touching && (settleAnimation == null || !settleAnimation.isStarted())) {
                removeCallbacks(settleAfterNonTouchScroll);
                postDelayed(settleAfterNonTouchScroll, NON_TOUCH_IDLE_MS);
            }
        }

        @Override
        protected void onDetachedFromWindow() {
            stopSettling();
            super.onDetachedFromWindow();
        }
    }

    private int dp(float value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private GradientDrawable rounded(int color, int radius) {
        GradientDrawable background = new GradientDrawable();
        background.setColor(color);
        background.setCornerRadius(dp(radius));
        return background;
    }

    private TextView text(String label, int size, int color, boolean bold) {
        TextView view = new TextView(this);
        view.setText(label);
        view.setTextColor(color);
        view.setTextSize(size);
        view.setGravity(Gravity.CENTER);
        if (bold) view.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        return view;
    }

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        if (!preferences().contains("theme")) {
            String previousTheme = getPreferences(MODE_PRIVATE).getString("theme", "System");
            preferences().edit().putString("theme", previousTheme).apply();
        }
        applyTheme();
        getWindow().setStatusBarColor(BACKGROUND);
        getWindow().setNavigationBarColor(BACKGROUND);
        showHome();
    }

    private void applyTheme() {
        String choice = preferences().getString("theme", "System");
        boolean dark = choice.equals("Dark") || (choice.equals("System") &&
                (getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES);
        BACKGROUND = dark ? Color.rgb(20, 29, 27) : Color.rgb(247, 246, 240);
        CARD = dark ? Color.rgb(37, 51, 47) : Color.WHITE;
        INK = dark ? Color.rgb(200, 231, 220) : Color.rgb(36, 107, 96);
        foreground = dark ? Color.WHITE : Color.rgb(24, 45, 40);
        getWindow().setStatusBarColor(BACKGROUND);
        getWindow().setNavigationBarColor(BACKGROUND);
    }

    private void showHome() {
        settingsVisible = false;
        rows.clear();
        ScrollView scroll = new SnappingScrollView();
        scroll.setFillViewport(true);
        scroll.setClipToPadding(false);
        scroll.setBackgroundColor(BACKGROUND);
        scroll.setVerticalScrollBarEnabled(false);

        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        int sideInset = dp(18);
        content.setPadding(sideInset, dp(12), sideInset, dp(62));
        content.setGravity(Gravity.CENTER_HORIZONTAL);

        int hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY);
        String greeting = label(hour < 12 ? 0 : hour < 17 ? 1 : 2);
        TextView title = text(greeting, 19, foreground, true);
        content.addView(title, new LinearLayout.LayoutParams(-1, -2));

        TextView status = text("✓  " + label(3), 12, Color.rgb(4, 63, 55), true);
        status.setBackground(rounded(Color.rgb(213, 239, 220), 24));
        LinearLayout.LayoutParams statusParams = new LinearLayout.LayoutParams(-2, dp(30));
        statusParams.setMargins(0, dp(7), 0, dp(10));
        status.setPadding(dp(12), 0, dp(12), 0);
        content.addView(status, statusParams);

        boolean normalLauncher = preferences().getBoolean("launcherNormal", false);
        String[][] labels = {{label(4), label(5)},
                {normalLauncher ? "Apps" : label(8), normalLauncher ? label(8) : ""}};
        int[][] icons = {{android.R.drawable.ic_btn_speak_now, android.R.drawable.ic_dialog_email}, {normalLauncher ? android.R.drawable.ic_menu_view : android.R.drawable.ic_menu_preferences, android.R.drawable.ic_menu_preferences}};
        LauncherApps launcher = getSystemService(LauncherApps.class);
        List<LauncherActivityInfo> pinnedApps = new ArrayList<>();
        java.util.Set<String> selected = preferences().getStringSet("launcherPinned", Collections.emptySet());
        for (LauncherActivityInfo app : launcher.getActivityList(null, Process.myUserHandle())) {
            if (selected.contains(app.getComponentName().flattenToString())) pinnedApps.add(app);
        }
        Collections.sort(pinnedApps, (a, b) -> a.getLabel().toString().compareToIgnoreCase(b.getLabel().toString()));
        int baseRows = labels.length;
        int totalRows = baseRows + (pinnedApps.size() + 1) / 2;
        for (int rowIndex = 0; rowIndex < totalRows; rowIndex++) {
            LinearLayout row = new LinearLayout(this);
            row.setGravity(Gravity.CENTER);
            row.setClipChildren(false);
            for (int column = 0; column < 2; column++) {
                int pinnedIndex = (rowIndex - baseRows) * 2 + column;
                if (rowIndex >= baseRows && pinnedIndex >= pinnedApps.size()) continue;
                if (rowIndex < baseRows && labels[rowIndex][column].isEmpty()) continue;
                final LauncherActivityInfo pinned = rowIndex >= baseRows ? pinnedApps.get(pinnedIndex) : null;
                final String action = pinned == null ? labels[rowIndex][column] : pinned.getLabel().toString();
                LinearLayout tile = new LinearLayout(this);
                tile.setOrientation(LinearLayout.VERTICAL);
                tile.setGravity(Gravity.CENTER);
                tile.setBackground(rounded(CARD, 24));
                tile.setContentDescription(action);
                tile.setClickable(true);
                ImageView icon = new ImageView(this);
                if (pinned == null) {
                    icon.setImageResource(icons[rowIndex][column]);
                    icon.setColorFilter(INK);
                } else {
                    icon.setImageDrawable(pinned.getBadgedIcon(getResources().getDisplayMetrics().densityDpi));
                }
                icon.setContentDescription(null);
                TextView label = text(action, 12, INK, true);
                label.setMaxLines(2);
                tile.addView(icon, new LinearLayout.LayoutParams(dp(27), dp(27)));
                tile.addView(label);
                tile.setOnClickListener(v -> {
                    if (pinned != null) {
                        try {
                            launcher.startMainActivity(pinned.getComponentName(), Process.myUserHandle(), null, null);
                        } catch (ActivityNotFoundException | SecurityException exception) {
                            Toast.makeText(this, "App unavailable", Toast.LENGTH_SHORT).show();
                        }
                    } else if (action.equals(label(8))) {
                        showSettings();
                    } else if (normalLauncher && action.equals("Apps")) {
                        startActivity(new Intent(this, AppsActivity.class));
                    } else if (action.equals(label(4))) {
                        Intent intent = new Intent(this, AssistantActivity.class);
                        startActivity(intent);
                    } else {
                        Toast.makeText(this, label(19), Toast.LENGTH_SHORT).show();
                    }
                });
                LinearLayout.LayoutParams tileParams = new LinearLayout.LayoutParams(0, dp(72), 1);
                tileParams.setMargins(dp(3), 0, dp(3), 0);
                row.addView(tile, tileParams);
            }
            LinearLayout.LayoutParams rowParams = new LinearLayout.LayoutParams(-1, dp(72));
            rowParams.setMargins(0, 0, 0, dp(6));
            content.addView(row, rowParams);
            rows.add(row);
        }
        scroll.addView(content);
        setContentView(scroll);
        Runnable scaleRows = () -> {
            float center = scroll.getHeight() / 2f;
            for (View row : rows) {
                float rowCenter = row.getTop() + row.getHeight() / 2f - scroll.getScrollY();
                float distance = Math.min(1f, Math.abs(rowCenter - center) / Math.max(1f, center));
                float scale = 1f - 0.19f * distance;
                row.setScaleX(scale);
                row.setScaleY(scale);
                row.setAlpha(1f - 0.12f * distance);
            }
        };
        scroll.setOnScrollChangeListener((v, x, y, oldX, oldY) -> scaleRows.run());
        scroll.post(() -> {
            content.setPadding(sideInset, dp(12), sideInset, scroll.getHeight() / 2);
            scaleRows.run();
        });
    }

    private void addSetting(LinearLayout content, String label, Runnable action) {
        TextView button = text(label, 14, INK, true);
        button.setBackground(rounded(CARD, 22));
        button.setPadding(dp(8), 0, dp(8), 0);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, dp(52));
        params.setMargins(0, dp(4), 0, dp(4));
        content.addView(button, params);
        button.setOnClickListener(view -> action.run());
    }

    private void showSettings() {
        settingsVisible = true;
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(BACKGROUND);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setGravity(Gravity.CENTER_HORIZONTAL);
        content.setPadding(dp(30), dp(24), dp(30), dp(60));
        content.addView(text(label(8), 20, foreground, true));
        addSetting(content, label(9) + ": " + LANGUAGES[preferences().getInt("language", 0)], () ->
                new AlertDialog.Builder(this).setTitle(label(9)).setItems(LANGUAGES, (dialog, which) -> {
                    preferences().edit().putInt("language", which).apply();
                    showSettings();
                }).show());

        String choice = preferences().getString("theme", "System");
        int themeIndex = choice.equals("Light") ? 12 : choice.equals("Dark") ? 13 : 11;
        addSetting(content, label(10) + ": " + label(themeIndex), () ->
                new AlertDialog.Builder(this)
                        .setTitle(label(10))
                        .setItems(new String[]{label(11), label(12), label(13)}, (dialog, which) -> {
                            String[] choices = {"System", "Light", "Dark"};
                            preferences().edit().putString("theme", choices[which]).apply();
                            applyTheme();
                            showSettings();
                        }).show());

        RoleManager roles = getSystemService(RoleManager.class);
        boolean isHome = roles.isRoleHeld(RoleManager.ROLE_HOME);
        addSetting(content, isHome ? label(15) : label(14), () -> {
            try {
                if (isHome) {
                    openSystemSettings(new Intent(Settings.ACTION_HOME_SETTINGS));
                } else if (roles.isRoleAvailable(RoleManager.ROLE_HOME)) {
                    startActivityForResult(roles.createRequestRoleIntent(RoleManager.ROLE_HOME), 1);
                } else {
                    Toast.makeText(this, "Home selection is unavailable on this watch", Toast.LENGTH_LONG).show();
                }
            } catch (Exception exception) {
                Toast.makeText(this, "Open watch settings to change the Home app", Toast.LENGTH_LONG).show();
            }
        });
        if (isHome) {
            boolean normal = preferences().getBoolean("launcherNormal", false);
            addSetting(content, normal ? "Launcher: Normal" : "Launcher: Minimal", () ->
                    new AlertDialog.Builder(this).setTitle("Launcher type")
                            .setItems(new String[]{"Minimal", "Normal (with apps)"}, (dialog, which) -> {
                                preferences().edit().putBoolean("launcherNormal", which == 1).apply();
                                showSettings();
                            }).show());
            if (normal) {
                addSetting(content, "Choose apps", () -> startActivity(
                        new Intent(this, AppsActivity.class).putExtra("choose", true)));
            }
            addSetting(content, "Add app tiles", () -> startActivity(
                    new Intent(this, AppsActivity.class).putExtra("choose", true).putExtra("pinned", true)));
        }
        boolean isAssistant = roles.isRoleHeld(RoleManager.ROLE_ASSISTANT);
        addSetting(content, isAssistant ? "Change assistant" : "Use Saathi as assistant", () -> {
            Intent intent = new Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS);
            openSystemSettings(intent);
        });
        addSetting(content, label(16), () -> openSystemSettings(new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, getPackageName())));
        addSetting(content, label(17), () -> openSystemSettings(new Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)));
        addSetting(content, label(18), this::showHome);
        scroll.addView(content);
        setContentView(scroll);
    }

    private void openSystemSettings(Intent intent) {
        try {
            returningFromSettings = true;
            startActivity(intent);
        } catch (ActivityNotFoundException exception) {
            returningFromSettings = false;
            Toast.makeText(this, "Unavailable on this watch", Toast.LENGTH_LONG).show();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (returningFromSettings) {
            returningFromSettings = false;
            applyTheme();
            showSettings();
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        if (intent.hasCategory(Intent.CATEGORY_HOME)) {
            showHome();
        }
    }

    @Override
    public void onBackPressed() {
        if (settingsVisible || getSystemService(RoleManager.class).isRoleHeld(RoleManager.ROLE_HOME)) {
            showHome();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 1) showSettings();
    }
}
