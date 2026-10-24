#!/data/data/com.termux/files/usr/bin/bash
# Gibt eine App frei (trägt den Paketnamen in allowed-apps.txt ein). Für den Nutzer, nicht für Claude.
# Nutzung: allow-app.sh NAME_ODER_PAKET [--force]
HANDY_DIR="${HANDY_DIR:-$HOME/handy}"; LIST="$HANDY_DIR/allowed-apps.txt"
q="${1#package:}"; force="$2"
[ -n "$q" ] || { echo "Nutzung: $0 NAME_ODER_PAKET [--force]" >&2; exit 2; }
if [[ "$q" == *.* ]]; then
  pkg="$q"
else
  hits=$(adb shell pm list packages 2>/dev/null | tr -d '\r' | sed 's/^package://' | grep -i "$q")
  n=$(printf '%s\n' "$hits" | grep -c .)
  if [ "$n" -eq 0 ]; then echo "Keine App mit \"$q\" im Paketnamen gefunden." >&2; exit 1; fi
  if [ "$n" -gt 1 ]; then echo "Mehrere Treffer, bitte den genauen Paketnamen angeben:" >&2; printf '%s\n' "$hits" >&2; exit 1; fi
  pkg="$hits"
fi
# Heikle Apps: nur mit --force
if printf '%s' "$pkg" | grep -qiE 'bank|paypal|wallet|pay\b|\.pay|authenticator|tan\b|phototan|password|bitwarden|keepass|whatsapp|signal|telegram|discord|messag|mms|contacts|dialer|telecom|settings|vending|packageinstaller|fdroid|termux|vpn|steam'; then
  if [ "$force" != "--force" ]; then
    echo "WARNUNG: $pkg sieht nach Geld, Konten, Kommunikation oder System aus. Nicht freigegeben." >&2
    echo "Wenn du es trotzdem willst: $0 $pkg --force" >&2; exit 3
  fi
fi
mkdir -p "$HANDY_DIR"; touch "$LIST"
if grep -qxF "$pkg" "$LIST"; then echo "Schon freigegeben: $pkg"; else echo "$pkg" >> "$LIST"; echo "Freigegeben: $pkg"; fi
