# UI-Verbesserungen (Overlay-App)
- Auftrag mit Enter speichern (bzw. Speichern+Starten), statt extra auf Speichern zu tippen
- Statusanzeige am Bedienfeld (läuft / fertig / Fehler)
- Größe und Farbe des Bedienfelds einstellbar
- Hauptseite: besseres Layout, richtiges App-Symbol
- Sichtbare Rückmeldung: Bedienfeld zeigt Zustand (bereit / läuft grün pulsierend / fertig / Fehler), ▶ wird beim Antippen kurz hervorgehoben, Ergebnis als Text am Bedienfeld
- WLAN-Test: Bedienfeld/Hauptseite zeigt "kein WLAN" und sperrt ▶, solange keine Verbindung besteht (ConnectivityManager)
- Wireless Debugging selbst einschalten: einmalig `pm grant dev.handy.macro android.permission.WRITE_SECURE_SETTINGS` (install-overlay.sh), App setzt dann Settings.Global adb_wifi_enabled=1; Verbindung danach über connect.sh (mDNS) in Termux
- Statusanzeige ADB (verbunden / nicht verbunden) am Bedienfeld
