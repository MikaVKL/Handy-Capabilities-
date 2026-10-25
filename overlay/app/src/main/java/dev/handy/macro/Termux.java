package dev.handy.macro;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.widget.Toast;

/** Schickt Befehle an Termux (RUN_COMMAND) und verwaltet den gespeicherten Auftrag. */
final class Termux {
    static final String HOME = "/data/data/com.termux/files/home";
    static final String MACRO = HOME + "/handy/scripts/macro.sh";
    static final String STOP = HOME + "/.shortcuts/tasks/Handy-Stop.sh";

    private Termux() {}

    static SharedPreferences prefs(Context c) {
        return c.getSharedPreferences("handy", Context.MODE_PRIVATE);
    }

    static String task(Context c) {
        return prefs(c).getString("task", "");
    }

    static void saveTask(Context c, String task) {
        prefs(c).edit().putString("task", task).apply();
    }

    /** Startet ein Skript in Termux im Hintergrund. */
    static boolean run(Context c, String script, String... args) {
        Intent i = new Intent("com.termux.RUN_COMMAND");
        i.setClassName("com.termux", "com.termux.app.RunCommandService");
        i.putExtra("com.termux.RUN_COMMAND_PATH", script);
        i.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", args);
        i.putExtra("com.termux.RUN_COMMAND_WORKDIR", HOME);
        i.putExtra("com.termux.RUN_COMMAND_BACKGROUND", true);
        try {
            c.startForegroundService(i);
            return true;
        } catch (SecurityException e) {
            Toast.makeText(c, "Keine Termux-Erlaubnis (RUN_COMMAND). Einrichtung prüfen.", Toast.LENGTH_LONG).show();
        } catch (Exception e) {
            Toast.makeText(c, "Termux nicht erreichbar: " + e.getMessage(), Toast.LENGTH_LONG).show();
        }
        return false;
    }

    static void start(Context c, String task) {
        if (task == null || task.trim().isEmpty()) {
            Toast.makeText(c, "Kein Auftrag gespeichert (✎ antippen).", Toast.LENGTH_SHORT).show();
            return;
        }
        String problem = Checks.blocker(c);
        if (problem != null) {
            Toast.makeText(c, problem, Toast.LENGTH_LONG).show();
            return;
        }
        Boolean ab = Checks.autoBlocker(c);
        if (ab != null && ab) Toast.makeText(c, "Auto Blocker ist an – Debugging kann abgeschaltet werden.", Toast.LENGTH_SHORT).show();
        run(c, MACRO, task.trim());
    }

    static void stop(Context c) {
        run(c, STOP);
    }
}
