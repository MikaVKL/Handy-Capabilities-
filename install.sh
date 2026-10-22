#!/data/data/com.termux/files/usr/bin/bash
# In Termux ausführen: richtet ~/handy und die Widget-Knöpfe ein.
set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HOME/handy" "$HOME/.shortcuts"
cp -r "$SRC/scripts" "$SRC/CLAUDE.md" "$HOME/handy/"
cp "$SRC/widget/Handy-Start.sh" "$SRC/widget/Handy-Stop.sh" "$HOME/.shortcuts/"
chmod +x "$HOME/handy/scripts/"*.sh "$HOME/.shortcuts/"*.sh
[ -f "$HOME/handy/allowed-apps.txt" ] || printf '# ein Paketname pro Zeile\n' > "$HOME/handy/allowed-apps.txt"
echo "Fertig. Widget 'Termux:Widget' auf den Startbildschirm legen."
