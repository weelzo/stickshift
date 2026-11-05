#!/bin/zsh
# Stickshift installer. Safe to re-run: it merges its own rules into your Karabiner config
# (your rules stay), backs files up before replacing them, and never rebuilds helper apps
# that already exist (rebuilding would reset their macOS permissions).
#
#   ./install.sh [remote|dictation|full] [--boya] [--rebuild-helpers]
#   ./install.sh --uninstall
#
#   remote     buttons only: paste, delete, Enter, Esc, scroll, app switcher, Zoom, Keynote
#   dictation  + mic button for a dictation app (Handy by default, shortcut Left Option)
#   full       + kaza voice dispatcher and spoken agent status (Herdr + Claude Code + Ghostty)
#   --boya     warn when a USB mic is switched off (see README, needs calibration)
set -euo pipefail
cd "${0:A:h}"

level=remote; boya=0; rebuild=0; uninstall=0
for arg in "$@"; do
  case $arg in
    remote|dictation|full) level=$arg ;;
    --boya) boya=1 ;;
    --rebuild-helpers) rebuild=1 ;;
    --uninstall) uninstall=1 ;;
    *) echo "Unknown option: $arg (see the top of install.sh)"; exit 2 ;;
  esac
done

K=~/.config/karabiner
APPS=~/Applications
PY=/usr/bin/python3

if (( uninstall )); then
  $PY -I karabiner/install_rules.py --uninstall
  cat <<EOF
Left in place on purpose (delete them yourself if you want):
  $APPS/AppSwitcher.app  $APPS/BoyaCheck.app
  $K/switcher.sh  $K/AppSwitcher.applescript  $K/boya-check.sh  $K/waiting.py
  ~/kaza (only if you installed the full level)
Permissions you granted stay in System Settings > Privacy & Security.
EOF
  exit 0
fi

# ---------- preflight ----------
missing=()
[[ $(uname) == Darwin ]] || { echo "Stickshift is macOS only."; exit 1; }
brew_prefix=$(brew --prefix 2>/dev/null || echo /opt/homebrew)

if [[ ! -d /Applications/Karabiner-Elements.app ]]; then
  if command -v brew >/dev/null; then
    # The cask runs a pkg with sudo, which fails without a terminal password prompt,
    # so fetch it and open the pkg in the normal macOS installer instead.
    brew fetch --cask karabiner-elements
    open "$(brew --cache --cask karabiner-elements)"
    echo "Finish the Karabiner-Elements installer (open the .pkg in the window that appeared), then re-run ./install.sh $*"
  else
    echo "Install Karabiner-Elements from https://karabiner-elements.pqrs.org, then re-run ./install.sh $*"
  fi
  exit 0
fi
if [[ $level != remote && ! -d /Applications/Handy.app ]]; then
  echo "Note: Handy (https://handy.computer) not found. The mic button sends a Left Option tap,"
  echo "      so any dictation app whose toggle shortcut is Left Option works too."
fi
if [[ $level == full ]]; then
  command -v herdr  >/dev/null || missing+=("herdr (https://herdr.dev)")
  command -v claude >/dev/null || missing+=("claude (Claude Code: https://claude.com/claude-code)")
  [[ -d /Applications/Ghostty.app ]] || missing+=("Ghostty (https://ghostty.org)")
fi
if (( boya )); then
  command -v sox >/dev/null || { command -v brew >/dev/null && brew install sox || missing+=("sox (brew install sox)"); }
fi
if (( ${#missing} )); then
  printf 'Missing for the %s level:\n' $level; printf '  - %s\n' "${missing[@]}"; exit 1
fi
apps=(); [[ -d /Applications/ChatGPT.app ]] && apps+=(--chatgpt); [[ -d /Applications/Claude.app ]] && apps+=(--claude-app)

# ---------- files ----------
mkdir -p $K $APPS
place() {  # place <repo file> : copies into ~/.config/karabiner with paths filled in, backing up a different existing copy
  local src=karabiner/$1 dst=$K/$1 tmp
  tmp=$(mktemp)
  sed -e "s|__HOME__|$HOME|g" -e "s|__BREW__|$brew_prefix|g" "$src" > "$tmp"
  if [[ -f $dst ]] && ! cmp -s "$tmp" "$dst"; then cp "$dst" "$dst.bak.$(date +%s)"; fi
  mv "$tmp" "$dst"; chmod +x "$dst" 2>/dev/null || true
}
build_app() {  # build_app <name> <bundle id> <applescript file or -e code> <background-only: true|false>
  local app=$APPS/$1.app
  if [[ -d $app && $rebuild == 0 ]]; then echo "Keeping existing $1.app (use --rebuild-helpers to replace it)"; return; fi
  rm -rf "$app"
  if [[ -f $3 ]]; then osacompile -o "$app" "$3"; else osacompile -o "$app" -e "$3"; fi
  plutil -replace CFBundleIdentifier -string "$2" "$app/Contents/Info.plist"
  plutil -replace LSUIElement -bool "$4" "$app/Contents/Info.plist"
  codesign --force --deep -s - "$app" >/dev/null 2>&1
  echo "Built $1.app"
}

place switcher.sh
place AppSwitcher.applescript
# AppSwitcher must come to the front to get keyboard focus, so it is not background-only.
build_app AppSwitcher dev.stickshift.AppSwitcher $K/AppSwitcher.applescript false

if (( boya )); then
  place boya-check.sh
  build_app BoyaCheck dev.stickshift.BoyaCheck "do shell script quoted form of \"$K/boya-check.sh\"" true
fi

if [[ $level == full ]]; then
  place waiting.py
  mkdir -p ~/kaza/.claude
  for f in CLAUDE.md .claude/settings.json; do
    if [[ -f ~/kaza/$f ]] && ! cmp -s kaza/$f ~/kaza/$f; then cp ~/kaza/$f ~/kaza/$f.bak.$(date +%s); fi
    cp kaza/$f ~/kaza/$f
  done
fi

# ---------- Karabiner rules ----------
flags=(--level $level); (( boya )) && flags+=(--boya); flags+=($apps)
STICKSHIFT_BREW=$brew_prefix $PY -I karabiner/install_rules.py $flags

# ---------- what's left to do by hand ----------
cat <<'EOF'

Done. One-time steps left:
  1. System Settings > General > Login Items & Extensions > Driver Extensions:
     turn on Karabiner-DriverKit-VirtualHIDDevice (only the first time).
  2. Privacy & Security > Input Monitoring: allow karabiner_grabber and karabiner_observer.
  3. Pair the remote: hold Home ~10 s, click Connect on "AR" in Bluetooth settings right away,
     quit the Keyboard Setup Assistant that pops up.
EOF
[[ $level != remote ]] && cat <<'EOF'
  4. Handy: transcribe shortcut = Left Option, push to talk OFF (toggle mode).
EOF
(( boya )) && cat <<'EOF'
  5. Run once and allow the microphone:  open -g -a ~/Applications/BoyaCheck.app
     Then calibrate THRESHOLD in ~/.config/karabiner/boya-check.sh (README, "Mic-off warning").
EOF
[[ $level == full ]] && cat <<'EOF'
  6. kaza: in Herdr run
       herdr tab create --cwd ~/kaza --label kaza
       herdr agent start kaza --kind claude --pane <root_pane id printed above>
     accept the folder trust prompt, then type /model haiku in it.
EOF
exit 0
