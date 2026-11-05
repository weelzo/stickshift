-- Remote app switcher. Built into ~/Applications/AppSwitcher.app so it gets keyboard focus.
-- Up/Down (or Left/Right via Karabiner) to pick, Select to open, Mute (Esc) to cancel.
set raw to do shell script "$HOME/.config/karabiner/switcher.sh"
set apps to paragraphs of raw
if (count of apps) < 2 then return
activate
set c to choose from list apps with title "Switch app" with prompt "Up/Down to pick, Select to open, Mute to cancel" default items {item 2 of apps} OK button name "Open"
if c is not false then do shell script "open -a " & quoted form of (item 1 of c)
