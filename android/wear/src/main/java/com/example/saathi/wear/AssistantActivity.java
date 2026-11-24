package com.example.saathi.wear;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Bundle;
import android.speech.RecognizerIntent;
import android.text.InputType;
import android.view.Gravity;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.util.ArrayList;
import java.util.UUID;
import java.nio.charset.StandardCharsets;
import org.json.JSONObject;
import org.json.JSONException;
import com.google.android.gms.wearable.CapabilityClient;
import com.google.android.gms.wearable.Wearable;

public class AssistantActivity extends Activity {
    private static final int REQUEST_SPEECH = 17;
    private static final String[][] TEXT = {
        {"Talk to Saathi", "Voice conversations are not connected yet. You can create a message draft.", "Message draft", "Speak", "Review on phone", "Back", "Speak your message"},
        {"சாதியிடம் பேசுங்கள்", "குரல் உரையாடல் இன்னும் இணைக்கப்படவில்லை. செய்தியை எழுதலாம்.", "செய்தி வரைவு", "பேசுங்கள்", "தொலைபேசியில் பார்க்க", "பின்", "உங்கள் செய்தியைப் பேசுங்கள்"},
        {"ಸಾಥಿಯೊಂದಿಗೆ ಮಾತನಾಡಿ", "ಧ್ವನಿ ಸಂಭಾಷಣೆ ಇನ್ನೂ ಸಂಪರ್ಕಗೊಂಡಿಲ್ಲ. ಸಂದೇಶ ಬರೆಯಬಹುದು.", "ಸಂದೇಶ ಕರಡು", "ಮಾತನಾಡಿ", "ಫೋನ್‌ನಲ್ಲಿ ಪರಿಶೀಲಿಸಿ", "ಹಿಂದೆ", "ನಿಮ್ಮ ಸಂದೇಶವನ್ನು ಹೇಳಿ"},
        {"సాథితో మాట్లాడండి", "వాయిస్ సంభాషణ ఇంకా అందుబాటులో లేదు. సందేశం రాయవచ్చు.", "సందేశం ముసాయిదా", "మాట్లాడండి", "ఫోన్‌లో పరిశీలించండి", "వెనుకకు", "మీ సందేశం చెప్పండి"},
        {"സാഥിയോട് സംസാരിക്കുക", "ശബ്ദ സംഭാഷണം ഇതുവരെ ലഭ്യമല്ല. സന്ദേശം എഴുതാം.", "സന്ദേശ കരട്", "സംസാരിക്കുക", "ഫോണിൽ പരിശോധിക്കുക", "തിരികെ", "നിങ്ങളുടെ സന്ദേശം പറയുക"}
    };
    private int language;
    private static final String[] VOICE_LANGUAGES = {"en-IN", "ta-IN", "kn-IN", "te-IN", "ml-IN"};
    private EditText draft;
    private TextView status;
    private boolean sending;
    private String draftId;
    private String lastDraft;

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        language = Math.max(0, Math.min(getSharedPreferences("wear_settings", MODE_PRIVATE)
                .getInt("language", 0), TEXT.length - 1));
        String theme = getSharedPreferences("wear_settings", MODE_PRIVATE).getString("theme", "System");
        boolean dark = theme.equals("Dark") || (theme.equals("System")
                && (getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK)
                == Configuration.UI_MODE_NIGHT_YES);
        int background = dark ? Color.rgb(20, 29, 27) : Color.rgb(247, 246, 240);
        int foreground = dark ? Color.WHITE : Color.rgb(24, 45, 40);
        getWindow().setStatusBarColor(background);
        getWindow().setNavigationBarColor(background);

        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(background);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setGravity(Gravity.CENTER_HORIZONTAL);
        int padding = (int) (24 * getResources().getDisplayMetrics().density);
        content.setPadding(padding, padding, padding, padding * 2);

        TextView title = new TextView(this);
        title.setText(TEXT[language][0]);
        title.setTextColor(foreground);
        title.setTextSize(18);
        title.setGravity(Gravity.CENTER);
        content.addView(title);

        status = new TextView(this);
        status.setText(TEXT[language][1]);
        status.setTextColor(foreground);
        status.setGravity(Gravity.CENTER);
        content.addView(status);

        draft = new EditText(this);
        draft.setTextColor(foreground);
        draft.setHintTextColor(foreground);
        draft.setHint(TEXT[language][2]);
        draft.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE
                | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        if (state != null) draft.setText(state.getString("draft", ""));
        else if (getIntent().hasExtra("draft")) draft.setText(getIntent().getStringExtra("draft"));
        content.addView(draft);

        Button speak = new Button(this);
        speak.setText(TEXT[language][3]);
        speak.setOnClickListener(view -> startSpeech());
        content.addView(speak);

        Button send = new Button(this);
        send.setText(TEXT[language][4]);
        send.setOnClickListener(view -> sendDraft());
        content.addView(send);

        Button back = new Button(this);
        back.setText(TEXT[language][5]);
        back.setOnClickListener(view -> finish());
        content.addView(back);
        scroll.addView(content);
        setContentView(scroll);
    }

    private void sendDraft() {
        String message = draft.getText().toString().trim();
        if (message.isEmpty() || message.length() > 2000) {
            status.setText("Enter a message of up to 2000 characters.");
            return;
        }
        if (sending) return;
        if (!message.equals(lastDraft)) {
            draftId = UUID.randomUUID().toString();
            lastDraft = message;
        }
        JSONObject payload = new JSONObject();
        try {
            payload.put("id", draftId);
            payload.put("text", message);
            payload.put("timestamp", System.currentTimeMillis());
        } catch (JSONException exception) {
            status.setText("Could not prepare the draft.");
            return;
        }
        sending = true;
        status.setText("Finding your phone…");
        Wearable.getCapabilityClient(this)
                .getCapability("saathi_phone_drafts_v1", CapabilityClient.FILTER_REACHABLE)
                .addOnSuccessListener(capability -> {
                    if (capability.getNodes().size() != 1) {
                        sending = false;
                        status.setText("Connect one phone with Saathi to review your draft.");
                        return;
                    }
                    String node = capability.getNodes().iterator().next().getId();
                    Wearable.getMessageClient(this).sendRequest(node, "/saathi/draft/v1",
                            payload.toString().getBytes(StandardCharsets.UTF_8))
                            .addOnSuccessListener(response -> {
                                sending = false;
                                String result = new String(response, StandardCharsets.UTF_8);
                                if ("accepted".equals(result)) {
                                    status.setText("Draft received on phone. Open Saathi to review it.");
                                } else if ("busy".equals(result)) {
                                    status.setText("Review the previous watch draft on your phone first.");
                                } else {
                                    status.setText("The phone could not accept the draft.");
                                }
                            })
                            .addOnFailureListener(error -> {
                                sending = false;
                                status.setText("Could not confirm delivery. Your draft is still here.");
                            });
                })
                .addOnFailureListener(error -> {
                    sending = false;
                    status.setText("Phone unavailable. Your draft is still here.");
                });
    }

    private void startSpeech() {
        int language = getSharedPreferences("wear_settings", MODE_PRIVATE).getInt("language", 0);
        language = Math.max(0, Math.min(language, VOICE_LANGUAGES.length - 1));
        Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, VOICE_LANGUAGES[language]);
        intent.putExtra(RecognizerIntent.EXTRA_PROMPT, TEXT[language][6]);
        try {
            startActivityForResult(intent, REQUEST_SPEECH);
        } catch (ActivityNotFoundException exception) {
            status.setText("Speech input is unavailable. You can type your message.");
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != REQUEST_SPEECH || resultCode != RESULT_OK || data == null) return;
        ArrayList<String> results = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
        if (results != null && !results.isEmpty()) {
            draft.setText(results.get(0));
            draft.setSelection(draft.length());
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle state) {
        state.putString("draft", draft.getText().toString());
        super.onSaveInstanceState(state);
    }
}
