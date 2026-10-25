#!/data/data/com.termux/files/usr/bin/bash
# In Termux ausführen: richtet ~/handy und die Widget-Knöpfe ein.
set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HOME/handy" "$HOME/.shortcuts"
cp -r "$SRC/scripts" "$SRC/apps" "$SRC/CLAUDE.md" "$HOME/handy/"
mkdir -p "$HOME/.shortcuts/tasks"
cp "$SRC/widget/Handy-Start.sh" "$SRC/widget/Handy-Stop.sh" "$HOME/.shortcuts/"
cp "$SRC/widget/Handy-Start.sh" "$SRC/widget/Handy-Stop.sh" "$HOME/.shortcuts/tasks/"
chmod +x "$HOME/handy/scripts/"*.sh "$HOME/handy/scripts/"*.py "$HOME/.shortcuts/"*.sh "$HOME/.shortcuts/tasks/"*.sh
[ -f "$HOME/handy/allowed-apps.txt" ] || printf '# ein Paketname pro Zeile\n' > "$HOME/handy/allowed-apps.txt"
echo "Fertig. Widget 'Termux:Widget' auf den Startbildschirm legen."
