#!/bin/zsh
# Says "Boya is off" when the Boya's USB receiver delivers near-silence
# (transmitter switched off or battery dead). Run by the remote's mic/Menu rules.
# Note: one hand-calibrated threshold; re-measure if mic gain or room changes.
THRESHOLD=0.0006          # calibrate: halfway between "off" and "on, quiet" peaks (see the log)
DEVICE="USB Audio"        # input device name as macOS shows it (System Settings > Sound > Input)
LABEL="Boya"              # what gets spoken: "<LABEL> is off"

max=$(__BREW__/bin/sox -V1 -t coreaudio "$DEVICE" -n trim 0 0.3 stat 2>&1 | awk '/Maximum amplitude/{print $3}')

print "$(date +%T) max=$max" >> ~/.config/karabiner/boya-check.log
if [[ -z "$max" ]] || (( max < THRESHOLD )); then
  say "$LABEL is off" &
  osascript -e 'display notification "Turn it on, dictation is hearing silence" with title "'"$LABEL"' is off"'
fi
