#!/data/data/com.termux/files/usr/bin/bash
# Verbindet Termux per Wireless debugging mit dem Handy. Für den Nutzer, nicht für Claude.
# Nutzung: connect.sh            (Adresse und Port automatisch per mDNS suchen)
#          connect.sh PORT [IP]  (nur Port angeben; IP von der letzten Verbindung oder aus dem WLAN)
HANDY_DIR="${HANDY_DIR:-$HOME/handy}"; STATE="$HANDY_DIR/state"; mkdir -p "$STATE"
IPFILE="$STATE/adb-ip"
target=""
found=$(timeout 6 adb mdns services 2>/dev/null | grep '_adb-tls-connect' | head -n 1 | awk '{print $NF}')
if [ -n "$found" ]; then
  target="$found"
elif [ -n "$1" ]; then
  case "$1" in *[!0-9]*) echo "Der Port besteht nur aus Ziffern, z. B. 39043" >&2; exit 2;; esac
  ip="$2"
  [ -n "$ip" ] || ip=$(cat "$IPFILE" 2>/dev/null)
  [ -n "$ip" ] || ip=$(termux-wifi-connectioninfo 2>/dev/null | sed -n 's/.*"ip": *"\([0-9.]*\)".*/\1/p')
  [ -n "$ip" ] || { echo "IP unbekannt. Einmalig: connect.sh PORT IP (die IP steht bei Wireless debugging)" >&2; exit 2; }
  target="$ip:$1"
else
  echo "Keine Adresse per mDNS gefunden. Port aus 'Wireless debugging' ablesen und: connect.sh PORT [IP]" >&2
  exit 1
fi
adb disconnect >/dev/null 2>&1
adb connect "$target"
if [ "$(adb get-state 2>/dev/null)" = "device" ]; then
  echo "${target%:*}" > "$IPFILE"
  echo "Verbunden mit $target"
else
  echo "Nicht verbunden. Ist Wireless debugging an, und stimmt der Port?" >&2; exit 1
fi
