package dev.handy.macro;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
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
        if (panel == null) show();
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

        TextView grip = label("KI", Color.rgb(180, 180, 255));
        row.addView(grip);
        row.addView(button("▶", Color.rgb(90, 200, 120), () -> Termux.start(this, Termux.task(this))));
        row.addView(button("■", Color.rgb(230, 90, 90), () -> Termux.stop(this)));
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
        v.setOnClickListener(x -> r.run());
        return v;
    }

    @Override
    public void onDestroy() {
        if (panel != null) {
            try { wm.removeView(panel); } catch (Exception ignored) {}
            panel = null;
        }
        super.onDestroy();
    }
}
