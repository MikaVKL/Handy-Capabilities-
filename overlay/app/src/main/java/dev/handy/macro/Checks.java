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
        return Settings.Global.getInt(c.getContentResolver(), "adb_wifi_enabled", 0) == 1;
    }

    /** true = an, false = aus, null = nicht ermittelbar (Schlüssel je nach One UI-Version verschieden). */
    static Boolean autoBlocker(Context c) {
        for (String key : new String[]{"auto_blocker_enabled", "autoblocker_enabled"}) {
            int v = Settings.Secure.getInt(c.getContentResolver(), key, -1);
            if (v < 0) v = Settings.Global.getInt(c.getContentResolver(), key, -1);
            if (v >= 0) return v == 1;
        }
        return null;
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
