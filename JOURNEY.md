# Journey

How this setup came together, including the dead ends. Read this before changing something that looks odd, because most odd things are there for a reason.

## 1. The starting idea
Use the Fire TV remote's mic button as push-to-talk: open the mic while held for meetings, and dictate into Handy or Claude Code. Three apps already support "hold a key to talk": Zoom and Meet (hold Space), Claude Code voice mode (hold Space), Handy (its shortcut). So the remote only needs to act like a held key.

## 2. The USB mic and its battery (dropped)
The Boya runs on AA batteries and has a physical power button, and it drained when left on. Ideas looked at:
- Keep it on and mute in software (input volume 0 until the button is held). Rejected, it doesn't solve the battery.
- Have the Mac press the mic's button through a relay. Rejected: the mic takes seconds to start up and reconnect, a toggle button gets out of step, and it means soldering.
- AA dummy battery on USB power. Works, but too much hassle for now.

What stayed: the **Boya-off warning** (section 6).

## 3. Brainstorm of bigger ideas
Approval key for risky agent commands, a "Jarvis" voice button, a meeting "clip that" button, couch code review, a talking rubber duck, tap codes, the Fire TV Stick as a status board on a monitor's HDMI input, AirPods nod-to-approve, the spare MacBook as an agent server. Deliberately limited to hardware already owned. The voice dispatcher (kaza) is the one that got built.

## 4. kaza
Herdr turned out to have a full CLI (`tab focus`, `agent prompt`, `pane split`, `agent start`), so the dispatcher needed no code, just a Claude Code session with a CLAUDE.md.
- First version: it "sent" prompts that were only typed into the target's input box, so I had to say "send it" every time. Fix: `--wait --until working`, one Enter retry, never claim "sent" before seeing `working`.
- Switched from Opus to Haiku for speed.
- `herdr agent wait` and `send-keys … enter` are not in its pre-approved list, because Claude Code settings files should be edited by a human. Claude Code asks once, and the user can allow them.

## 5. Remote + Karabiner
- `brew install --cask` needs a sudo password the `!` shell can't take. Opening the pkg directly works.
- The driver stayed `activated waiting for user` until it was approved in Login Items & Extensions. Before that, nothing remapped and the buttons kept their defaults (mic opened Spotlight search, Play paused YouTube).
- Pairing: the remote shows up as "AR". Pairing mode only lasts about 30 seconds, so click Connect right away.
- First button map: mic = Handy, Menu = kaza, Play = Enter. Then Select turned out to already send `keypad_enter`, so the Play = Enter rule was deleted.

## 6. Boya-off warning
- First version always said "Boya is off". Its log showed `max=0.000000`: scripts launched by Karabiner have no microphone permission, and macOS returns silence without asking. Fix: BoyaCheck.app wrapper with its own mic permission.
- Then it never warned: the receiver sends faint noise (about 0.00025) even with the transmitter off, above the first threshold of 0.0002. Recalibrated to 0.0006.
- Presses right after each other were skipped, because `open -a` doesn't relaunch an app that's still running. Fix: `open -n`.

## 7. Hold vs toggle
Hold-to-talk was tiring for long dictation. The mic button now sends one Option tap per press, which matches Handy's own toggle mode. Menu (kaza) stays hold-to-talk, since commands are short.

## 8. Editing buttons
Home = paste (hold = image paste via Ctrl+V, which Claude Code uses for images). Rewind = Backspace. Fast-forward = delete word: Left Option + Backspace started Handy, because Handy's shortcut is Left Option, and Handy swallowed the modifier. Right Option + Backspace no longer starts Handy but still deletes only a character in Ghostty. Unsolved.

## 9. Dead buttons
Back, TV and the 4 app buttons send nothing, not even as raw records. The HID descriptor shows an Amazon vendor collection (`0xFF00`) that stays silent on a Mac. A web search found only other people hitting the same wall. Reverse-engineering the handshake would need a Bluetooth sniffer, which isn't worth it. App launching moved to voice ("open Slack" through kaza).

## 10. Per-app layers, then fewer of them
Built layers for Chrome (Meet controls, YouTube play), Slack (unread navigation, huddle mute, Cmd+K), Keynote, Zoom, and a terminal mode that used Claude Code's own voice (`/voice tap`) with a Handy fallback.
In practice it was confusing: in Chrome, Play no longer went back to the previous window, and Mute bookmarked pages (Cmd+D), because Karabiner can't tell a Meet tab from any other tab. Claude voice mode didn't start, because the setting was still `hold`.
**Decision: every button means the same thing everywhere**, except in Zoom and Keynote, which are modes you consciously enter. Chrome, Slack and terminal-voice layers were removed.

Useful facts found along the way:
- Claude Code voice has `voice.mode: "hold" | "tap"`. You switch with `/voice tap`, and the trigger is rebindable as `voice:pushToTalk` in `~/.claude/keybindings.json`.
- Handy has `--toggle-transcription` for scripts.

## 11. Sleep wakes
After pairing, the Mac kept waking at night. The power log compares the night before and the night after (see the README). Cause: the remote's own Bluetooth traffic. Also found: Claude Code runs `caffeinate -i -t 300` while agents work, which keeps the Mac from falling asleep (by design). `blueutil` can't disconnect this BLE remote, so a "power button = disconnect" rule was built and then removed. Still open: turn Bluetooth off on sleep with `sleepwatcher`, batteries out, or both.

## 12. App switcher
Tap Play = Cmd+Tab only reaches the previous app. Holding Play to keep Apple's switcher open and moving with Left/Right failed: the remote reports one button at a time, so pressing Right releases Play and the switcher closes. Apple's switcher can't stay open without a held key, so Play now opens a `choose from list` dialog of open apps instead. The first version ran the dialog from a script and it never got keyboard focus (remote presses went to the app behind it). Fix: compile it into AppSwitcher.app (with a bundle ID for Karabiner's Left/Right rule) and launch it with `open -a` (from `lsappinfo visibleProcessList`, most recent first). Select opens, Mute (Esc) cancels, and Left/Right are mapped to Up/Down while the dialog is in front. "What's waiting" moved from hold Play to hold Mute.

## 13. Codex app layer and MenuReader
Codex Micro only works with Codex inside the ChatGPT desktop app (its bundle ID really is `com.openai.codex`): agent keys per chat, accept, reject, push-to-talk, new chat, send, a joystick for canned tasks, a reasoning dial. To copy that, I needed the app's shortcuts. Reading another app's menus needs Automation (System Events) **and** Accessibility. Granting both to Ghostty did nothing, because the shell's process chain goes up to the Herdr server, not Ghostty. Fix: MenuReader.app, a small applet with its own Accessibility permission.
Findings: previous/next chat = Option+Cmd+[ / ], new chat = Cmd+N, "Your dot" lives under the Window menu with no shortcut, and the app's own voice button has no shortcut (only macOS dictation), so at first dictation stayed on Handy. Searching the app bundle later found a built-in "global dictation" with a hold hotkey (default Fn on macOS) and a configurable toggle hotkey. It lives under Settings > General > Dictation > Advanced as "Single-tap shortcut". Its recorder only accepts a single key, so Ctrl+Option+Cmd+D was impossible. It's set to Fn, and in ChatGPT the mic sends a Fn tap. The tap must be short: the first version held Fn as long as the button was held, and ChatGPT read that as hold-to-dictate. Now Fn is tapped and an empty `vk_none` is held instead. Fn was a dead end: macOS's own globe-key action (the emoji picker) fired on every tap, and setting `AppleFnUsageType` to 0 with `defaults` didn't apply without logging out. Switched to **Right Command**, which does nothing on its own in macOS, and restored the globe key setting. Also learned: ChatGPT refuses to save a dictation shortcut until it has Input Monitoring. Synthetic taps (0 ms, 120 ms) were ignored, while holding Right Command exactly as long as the remote button worked. Then dictation only ran while the button was held: Right Command had gone into the **hold** field (`globalDictationHotkey` in `~/.codex/.codex-global-state.json`) instead of the single-tap one (`globalDictationToggleHotkey`). Moving it to Single-tap gives tap to start, tap to stop.
Layer added: Up/Down switch chats, hold Select = new chat.
Hold Home opens "Your dot" from any app. First attempt: OpenDot.app clicking Window > Your dot. That failed, because the Window menu only lists open windows by title. Second attempt: press the sidebar button through Accessibility. That failed too, because the app is Electron and exposes only 11 accessibility elements (`AXManualAccessibility` can't be set from System Events). What worked: the app registers `codex://`, and its bundle contains `codex://dots`. Hold Home now runs `open codex://dots`: instant, no permission, works from any screen. OpenDot was deleted. Image paste moved from hold Home to double-tap Home (a Karabiner variable set on the first tap and cleared after 350 ms).

## 14. Publish prep
A read-only review by Codex judged it "not ready for strangers". The main findings, all fixed:
- The installer replaced the whole Karabiner config. Now `install_rules.py` merges only rules named `Stickshift: …` into the selected profile, backs up first, and `--uninstall` removes just those. Tested with throwaway home folders: a foreign rule survives install, re-install and uninstall.
- Three install levels (`remote`, `dictation`, `full`) plus `--boya`. Rules and single actions are filtered by what they need (Handy's Left Option, Herdr, BoyaCheck, `codex://`), so a buttons-only install never triggers missing tools.
- Helper apps are only built when missing, because rebuilding resets their macOS permissions. Scripts are backed up before replacement, and paths use `__HOME__` / `__BREW__` placeholders, filled in at install.
- MIT license, `.gitignore`, a logo, neutral examples instead of personal agent names, accurate claims (the mic toggles, what is local and what is cloud), and the mic-off check's device and label moved to variables.
Google Meet came back as a Chrome-wide layer (Mute = Cmd+D). A per-tab version with a watcher app that asks Chrome for the active URL was tried and dropped: it needed Automation permission and a login item, and broke during setup. Still open: delete-word in Ghostty, sleep wake-ups, and double tap Home pasting text before the image.

## 15. Claude app layer, lighter README
The Claude desktop app (`com.anthropic.claudefordesktop`) got the same layer as the ChatGPT app: MenuReader found New Chat = Cmd+N and Previous/Next Chat = Shift+Cmd+[ / ]. Its code has a `dictationShortcut` setting that, unlike ChatGPT's, accepts a key combination. Its default is already Command+D (start or stop), so the mic just sends that and no setup is needed. In both apps, Select now sends Return, because these Electron apps ignore the remote's keypad Enter for sending.
The README was cut down to what any user needs. The personal pieces (the Boya mic-off warning, MenuReader, the remote's HID details) moved to `docs/extras.md`.

## 16. Logo, round two
The purple version was replaced with a black and white one. Dropped along the way: a wide game-controller variant (it read as a console controller, not a Fire TV remote), floating sparkles, and a blinking eye (too busy). The final mark is a slim Fire TV-style remote: the top button, where Alexa's mic button sits, is an AI sparkle, and the direction ring holds a terminal prompt `>_`. The gear-shift gate that used to sit there read as the letters "HH", and a lever, a gear map, a waveform, an "S" and an eye were also tried. Below that, one row of buttons and a volume rocker. `logo-light.svg` (black) and `logo-dark.svg` (white) are swapped by a `<picture>` element, so GitHub shows the right one in light and dark mode. All logo files come from `tools/make-logo.sh`.

## Next
- Fix delete-word (try Ctrl+W).
- Decide on the sleep fix.
- Screen control beyond Herdr: kaza through app connectors (Slack, Linear, Notion) for most things, and macOS Voice Control for apps without one.
- Optional: a Fire TV Stick status board on the monitor's HDMI input.
