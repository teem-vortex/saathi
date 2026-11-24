package com.example.saathi.wear;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.LauncherActivityInfo;
import android.content.pm.LauncherApps;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Process;
import android.view.Gravity;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class AppsActivity extends Activity {
    private final List<LauncherActivityInfo> applications = new ArrayList<>();
    private SharedPreferences preferences;
    private int background;
    private int foreground;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        preferences = getSharedPreferences("wear_settings", MODE_PRIVATE);
        String theme = preferences.getString("theme", "System");
        boolean dark = theme.equals("Dark") || (theme.equals("System")
                && (getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK)
                == Configuration.UI_MODE_NIGHT_YES);
        background = dark ? Color.rgb(20, 29, 27) : Color.rgb(247, 246, 240);
        foreground = dark ? Color.WHITE : Color.rgb(24, 45, 40);
        getWindow().setStatusBarColor(background);
        getWindow().setNavigationBarColor(background);
        LauncherApps launcher = (LauncherApps) getSystemService(Context.LAUNCHER_APPS_SERVICE);
        for (LauncherActivityInfo app : launcher.getActivityList(null, Process.myUserHandle())) {
            if (!app.getComponentName().getPackageName().equals(getPackageName())) applications.add(app);
        }
        Collections.sort(applications, (a, b) -> a.getLabel().toString().compareToIgnoreCase(b.getLabel().toString()));
        if (getIntent().getBooleanExtra("choose", false)) showChooser();
        else showApps(launcher);
    }

    private void showChooser() {
        String[] names = new String[applications.size()];
        boolean[] selected = new boolean[applications.size()];
        boolean pinned = getIntent().getBooleanExtra("pinned", false);
        String key = pinned ? "launcherPinned" : "launcherApps";
        Set<String> existing = preferences.getStringSet(key, Collections.emptySet());
        Set<String> working = new HashSet<>(existing);
        for (int i = 0; i < applications.size(); i++) {
            LauncherActivityInfo app = applications.get(i);
            names[i] = app.getLabel().toString();
            selected[i] = working.contains(app.getComponentName().flattenToString());
        }
        new AlertDialog.Builder(this)
                .setTitle(pinned ? "Add app tiles" : "Choose apps")
                .setMultiChoiceItems(names, selected, (dialog, position, checked) -> {
                    String component = applications.get(position).getComponentName().flattenToString();
                    if (checked) working.add(component);
                    else working.remove(component);
                })
                .setPositiveButton("Save", (dialog, which) -> {
                    SharedPreferences.Editor edit = preferences.edit().putStringSet(key, working);
                    if (!pinned) edit.putBoolean("launcherAll", false);
                    edit.apply();
                    finish();
                })
                .setNeutralButton(pinned ? "Clear" : "Show all", (dialog, which) -> {
                    if (pinned) preferences.edit().remove(key).apply();
                    else preferences.edit().putBoolean("launcherAll", true).apply();
                    finish();
                })
                .setNegativeButton("Cancel", (dialog, which) -> finish())
                .setOnCancelListener(dialog -> finish())
                .show();
    }

    private void showApps(LauncherApps launcher) {
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(background);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setGravity(Gravity.CENTER_HORIZONTAL);
        int densityPadding = dp(24);
        content.setPadding(densityPadding, densityPadding, densityPadding, dp(60));

        TextView heading = new TextView(this);
        heading.setText("Apps");
        heading.setTextColor(foreground);
        heading.setTextSize(20);
        heading.setGravity(Gravity.CENTER);
        content.addView(heading);

        boolean all = preferences.getBoolean("launcherAll", true);
        Set<String> chosen = preferences.getStringSet("launcherApps", Collections.emptySet());
        int visibleCount = 0;
        for (LauncherActivityInfo app : applications) {
            if (!all && !chosen.contains(app.getComponentName().flattenToString())) continue;
            visibleCount++;
            LinearLayout button = new LinearLayout(this);
            button.setGravity(Gravity.CENTER_VERTICAL);
            button.setPadding(dp(8), dp(5), dp(8), dp(5));
            button.setContentDescription(app.getLabel());
            button.setClickable(true);
            ImageView icon = new ImageView(this);
            icon.setImageDrawable(app.getBadgedIcon(getResources().getDisplayMetrics().densityDpi));
            button.addView(icon, new LinearLayout.LayoutParams(dp(32), dp(32)));
            TextView name = new TextView(this);
            name.setText(app.getLabel());
            name.setTextColor(foreground);
            name.setTextSize(15);
            name.setPadding(dp(8), 0, 0, 0);
            button.addView(name, new LinearLayout.LayoutParams(0, -2, 1));
            button.setOnClickListener(view -> {
                try {
                    launcher.startMainActivity(app.getComponentName(), Process.myUserHandle(), null, null);
                } catch (ActivityNotFoundException | SecurityException exception) {
                    Toast.makeText(this, "App unavailable", Toast.LENGTH_SHORT).show();
                }
            });
            content.addView(button, new LinearLayout.LayoutParams(-1, dp(52)));
        }
        if (visibleCount == 0) {
            TextView empty = new TextView(this);
            empty.setText("No apps selected");
            empty.setTextColor(foreground);
            empty.setGravity(Gravity.CENTER);
            content.addView(empty);
        }
        TextView back = new TextView(this);
        back.setText("Back");
        back.setTextColor(foreground);
        back.setGravity(Gravity.CENTER);
        back.setOnClickListener(view -> finish());
        content.addView(back, new LinearLayout.LayoutParams(-1, dp(52)));
        scroll.addView(content);
        setContentView(scroll);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }
}
