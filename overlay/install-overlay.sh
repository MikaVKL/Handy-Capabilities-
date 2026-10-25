#!/data/data/com.termux/files/usr/bin/bash
# Installiert das schwebende Bedienfeld (KI-Makro) und richtet die Erlaubnisse ein.
# Voraussetzung: ADB verbunden (scripts/connect.sh), Termux:API nicht nötig.
DIR="$(cd "$(dirname "$0")" && pwd)"
APK="$DIR/dist/handy-macro-debug.apk"
P=dev.handy.macro
[ -f "$APK" ] || { echo "APK fehlt: $APK"; exit 1; }

# Termux darf Befehle von anderen Apps annehmen
mkdir -p ~/.termux
touch ~/.termux/termux.properties
grep -q '^allow-external-apps *= *true' ~/.termux/termux.properties \
  || echo 'allow-external-apps = true' >> ~/.termux/termux.properties
command -v termux-reload-settings >/dev/null && termux-reload-settings

adb install -r "$APK" || { echo "Installation fehlgeschlagen (Play Protect / Auto Blocker prüfen)"; exit 1; }
adb shell pm grant $P com.termux.permission.RUN_COMMAND
adb shell pm grant $P android.permission.POST_NOTIFICATIONS
adb shell pm grant $P android.permission.WRITE_SECURE_SETTINGS
adb shell appops set $P SYSTEM_ALERT_WINDOW allow
adb shell am start -n $P/.MainActivity >/dev/null
echo "Fertig. In der App 'Bedienfeld einblenden' tippen. Termux einmal komplett beenden und neu öffnen, damit allow-external-apps gilt."
