package dev.handy.macro;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Status und Einstieg: Bedienfeld ein/aus, Berechtigung, Auftrag. */
public class MainActivity extends Activity {
    private TextView status;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(48, 96, 48, 48);
        status = new TextView(this);
        status.setTextSize(16);
        status.setPadding(0, 0, 0, (int) (getResources().getDisplayMetrics().density * 16));
        root.addView(status);
        root.addView(btn("Bedienfeld einblenden", v -> {
            if (!Settings.canDrawOverlays(this)) {
                startActivity(new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + getPackageName())));
            } else {
                startForegroundService(new Intent(this, OverlayService.class));
            }
        }));
        root.addView(btn("Wireless Debugging einschalten", v -> {
            boolean ok = Checks.enableAdbWifi(this);
            android.widget.Toast.makeText(this, ok ? "Eingeschaltet" : "Geht nur nach install-overlay.sh (WRITE_SECURE_SETTINGS)", android.widget.Toast.LENGTH_LONG).show();
            onResume();
        }));
        root.addView(btn("Entwickleroptionen öffnen", v -> startActivity(new Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS))));
        root.addView(btn("Bedienfeld ausblenden", v -> stopService(new Intent(this, OverlayService.class))));
        root.addView(btn("Auftrag bearbeiten", v -> startActivity(new Intent(this, TaskActivity.class))));
        setContentView(root);
        requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 1);
    }

    @Override
    protected void onResume() {
        super.onResume();
        boolean ov = Settings.canDrawOverlays(this);
        boolean rc = checkSelfPermission("com.termux.permission.RUN_COMMAND") == PackageManager.PERMISSION_GRANTED;
        status.setText("Über anderen Apps: " + (ov ? "ja" : "NEIN")
                + "\nTermux-Erlaubnis: " + (rc ? "ja" : "NEIN (install-overlay.sh ausführen)")
                + "\n" + Checks.report(this)
                + "\nAuftrag: " + (Termux.task(this).isEmpty() ? "(leer)" : Termux.task(this)));
    }

    private Button btn(String t, android.view.View.OnClickListener l) {
        Button b = new Button(this);
        b.setText(t);
        b.setOnClickListener(l);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        int m = (int) (getResources().getDisplayMetrics().density * 8);
        lp.setMargins(0, m, 0, m);
        b.setLayoutParams(lp);
        return b;
    }
}
