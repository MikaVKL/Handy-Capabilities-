package dev.handy.macro;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.graphics.drawable.GradientDrawable;
import android.os.IBinder;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Schwebendes Bedienfeld: KI-Griff zum Verschieben, ▶ Start, ■ Stopp, ✎ Auftrag, ✕ Schließen. */
public class OverlayService extends Service {
    private static final String CHANNEL = "overlay";
    private WindowManager wm;
    private View panel;
    private WindowManager.LayoutParams lp;
    private TextView grip;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private final Runnable toIdle = () -> setState("idle", "");
    private final BroadcastReceiver statusRx = new BroadcastReceiver() {
        @Override
        public void onReceive(Context c, Intent i) {
            setState(i.getStringExtra("state"), i.getStringExtra("text"));
        }
    };

    @Override
    public IBinder onBind(Intent i) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        NotificationManager nm = getSystemService(NotificationManager.class);
        nm.createNotificationChannel(new NotificationChannel(CHANNEL, "KI-Makro Bedienfeld", NotificationManager.IMPORTANCE_MIN));
        Intent quit = new Intent(this, OverlayService.class).setAction("quit");
        PendingIntent pi = PendingIntent.getService(this, 0, quit, PendingIntent.FLAG_IMMUTABLE);
        Notification n = new Notification.Builder(this, CHANNEL)
                .setSmallIcon(R.drawable.ic_launcher)
                .setContentTitle("KI-Makro Bedienfeld aktiv")
                .addAction(new Notification.Action.Builder(null, "Beenden", pi).build())
                .setOngoing(true)
                .build();
        startForeground(1, n);
        if (intent != null && "quit".equals(intent.getAction())) {
            stopSelf();
            return START_NOT_STICKY;
        }
        if (panel == null) {
            show();
            registerReceiver(statusRx, new IntentFilter("dev.handy.macro.STATUS"), Context.RECEIVER_EXPORTED);
        }
        return START_STICKY;
    }

    private void show() {
        wm = getSystemService(WindowManager.class);
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(8, 8, 8, 8);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.argb(210, 30, 30, 36));
        bg.setCornerRadius(60);
        row.setBackground(bg);

        grip = label("KI", Color.rgb(180, 180, 255));
        row.addView(grip);
        row.addView(button("▶", Color.rgb(90, 200, 120), () -> {
            setState("starting", "");
            Termux.start(this, Termux.task(this));
        }));
        row.addView(button("■", Color.rgb(230, 90, 90), () -> {
            setState("stopped", "");
            Termux.stop(this);
        }));
        row.addView(button("✎", Color.WHITE, () -> startActivity(
                new Intent(this, TaskActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))));
        row.addView(button("✕", Color.LTGRAY, this::stopSelf));

        lp = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT, WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT);
        lp.gravity = Gravity.TOP | Gravity.START;
        lp.x = 20;
        lp.y = 300;

        grip.setOnTouchListener(new View.OnTouchListener() {
            int sx, sy;
            float tx, ty;

            @Override
            public boolean onTouch(View v, MotionEvent e) {
                switch (e.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        sx = lp.x; sy = lp.y; tx = e.getRawX(); ty = e.getRawY();
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        lp.x = sx + (int) (e.getRawX() - tx);
                        lp.y = sy + (int) (e.getRawY() - ty);
                        wm.updateViewLayout(panel, lp);
                        return true;
                }
                return false;
            }
        });
        panel = row;
        wm.addView(panel, lp);
    }

    /** Zeigt den Zustand am KI-Griff: Farbe und Text. */
    private void setState(String state, String text) {
        if (grip == null || state == null) return;
        ui.removeCallbacks(toIdle);
        int color; String t;
        switch (state) {
            case "starting": case "running": color = Color.rgb(90, 200, 120); t = "KI…"; break;
            case "done": color = Color.rgb(90, 200, 120); t = "KI ✓"; break;
            case "error": color = Color.rgb(230, 90, 90); t = "KI !"; break;
            case "stopped": color = Color.rgb(230, 170, 60); t = "KI ■"; break;
            default: color = Color.rgb(180, 180, 255); t = "KI";
        }
        grip.setTextColor(color);
        grip.setText(t);
        if (text != null && !text.isEmpty() && (state.equals("done") || state.equals("error"))) {
            android.widget.Toast.makeText(this, text, android.widget.Toast.LENGTH_LONG).show();
        }
        if (state.equals("done") || state.equals("error") || state.equals("stopped")) ui.postDelayed(toIdle, 6000);
    }

    private TextView label(String t, int color) {
        TextView v = new TextView(this);
        v.setText(t);
        v.setTextColor(color);
        v.setTextSize(18);
        v.setGravity(Gravity.CENTER);
        v.setPadding(28, 16, 28, 16);
        return v;
    }

    private TextView button(String t, int color, Runnable r) {
        TextView v = label(t, color);
        v.setOnClickListener(x -> {
            x.performHapticFeedback(android.view.HapticFeedbackConstants.KEYBOARD_TAP);
            x.animate().scaleX(1.5f).scaleY(1.5f).setDuration(90)
                    .withEndAction(() -> x.animate().scaleX(1f).scaleY(1f).setDuration(120).start()).start();
            r.run();
        });
        return v;
    }

    @Override
    public void onDestroy() {
        try { unregisterReceiver(statusRx); } catch (Exception ignored) {}
        if (panel != null) {
            try { wm.removeView(panel); } catch (Exception ignored) {}
            panel = null;
        }
        super.onDestroy();
    }
}
