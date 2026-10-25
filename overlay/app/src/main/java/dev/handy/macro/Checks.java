package dev.handy.macro;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.provider.Settings;

/** Vorbedingungen: WLAN, Wireless Debugging, Auto Blocker. */
final class Checks {
    private Checks() {}

    static boolean wifi(Context c) {
        ConnectivityManager cm = c.getSystemService(ConnectivityManager.class);
        Network n = cm.getActiveNetwork();
        NetworkCapabilities nc = n == null ? null : cm.getNetworkCapabilities(n);
        return nc != null && nc.hasTransport(NetworkCapabilities.TRANSPORT_WIFI);
    }

    static boolean adbWifi(Context c) {
        try {
            return Settings.Global.getInt(c.getContentResolver(), "adb_wifi_enabled", 0) == 1;
        } catch (RuntimeException e) {
            return false;
        }
    }

    /** true = an, false = aus, null = nicht ermittelbar. Samsung nennt den Auto Blocker intern "rampart"
     *  (Secure-Einstellungen rampart_blocked_*; 1 = Sperre aktiv). */
    static Boolean autoBlocker(Context c) {
        String[] keys = {"rampart_blocked_adb_cmd", "rampart_blocked_unknown_apps", "rampart_blocked_commands",
                "rampart_blocked_at_cmd", "rampart_blocked_keystring"};
        boolean found = false;
        for (String key : keys) {
            int v;
            try {
                v = Settings.Secure.getInt(c.getContentResolver(), key, -1);
            } catch (RuntimeException e) {     // nicht lesbare Systemeinstellung (SecurityException)
                return null;
            }
            if (v < 0) continue;
            found = true;
            if (v == 1) return true;
        }
        return found ? Boolean.FALSE : null;
    }

    static boolean canWriteSecure(Context c) {
        return c.checkSelfPermission("android.permission.WRITE_SECURE_SETTINGS")
                == android.content.pm.PackageManager.PERMISSION_GRANTED;
    }

    /** Schaltet Wireless Debugging ein (nur mit WRITE_SECURE_SETTINGS). */
    static boolean enableAdbWifi(Context c) {
        if (!canWriteSecure(c)) return false;
        try {
            return Settings.Global.putInt(c.getContentResolver(), "adb_wifi_enabled", 1);
        } catch (SecurityException e) {
            return false;
        }
    }

    /** Kurzer Statustext für die Hauptseite. */
    static String report(Context c) {
        Boolean ab = autoBlocker(c);
        return "WLAN: " + (wifi(c) ? "ja" : "NEIN (ohne WLAN keine Funktion)")
                + "\nWireless Debugging: " + (adbWifi(c) ? "an" : "AUS")
                + "\nAuto Blocker: " + (ab == null ? "unbekannt (in den Einstellungen prüfen)" : ab ? "AN (kann Debugging abschalten)" : "aus");
    }

    /** Fehlermeldung, wenn ein Start nicht möglich ist; null, wenn alles passt. */
    static String blocker(Context c) {
        if (!wifi(c)) return "Kein WLAN – ohne WLAN geht nichts.";
        if (!adbWifi(c)) {
            if (!enableAdbWifi(c)) return "Wireless Debugging ist aus. In den Entwickleroptionen einschalten.";
        }
        return null;
    }
}
