# Extras

Personal add-ons and deep dives. None of this is needed to use Stickshift. Each piece was built for one specific setup, so adjust it for yours.

## Mic-off warning (`./install.sh … --boya`)

Built for a wireless USB mic (a Boya) whose transmitter is easy to leave switched off. On every mic or Menu press, `boya-check.sh` samples the input for 0.3 s with `sox` and says "Boya is off" if it hears near-silence.

Adjust it for your mic by editing the top of `~/.config/karabiner/boya-check.sh`:

| Setting | Meaning |
|---|---|
| `DEVICE` | Input device name as macOS shows it (System Settings › Sound › Input) |
| `LABEL` | What gets spoken: "`<LABEL>` is off" |
| `THRESHOLD` | Halfway between your "off" and "on, quiet" peak readings |

Every reading is logged to `~/.config/karabiner/boya-check.log`, so calibrate from real numbers: press the mic button with the mic off a few times, then on. Readings for the original mic:

| State | Peak amplitude |
|---|---|
| Transmitter off | 0.00024 to 0.00037 (receiver noise, never exactly zero) |
| On, quiet room | 0.0011 to 0.0023 |
| On, speaking | 0.03 to 0.08 |

The check runs inside **BoyaCheck.app** because a script started by Karabiner has no microphone permission, and macOS silently hands it pure zeros instead of asking. Run `open -g -a ~/Applications/BoyaCheck.app` once and allow the microphone.

## MenuReader: find any app's shortcuts

To map a button to an app action, you need that app's shortcut. MenuReader dumps every menu item and its shortcut:

```sh
osacompile -o ~/Applications/MenuReader.app tools/MenuReader.applescript
plutil -replace CFBundleIdentifier -string dev.stickshift.MenuReader ~/Applications/MenuReader.app/Contents/Info.plist
codesign --force --deep -s - ~/Applications/MenuReader.app
echo "ChatGPT" > /tmp/menureader-target && open -W -a ~/Applications/MenuReader.app && cat /tmp/menureader-out.txt
```

Output looks like `File > New Chat  [0:N]`. Modifier codes: `0` Cmd, `1` Shift+Cmd, `2` Option+Cmd, `4` Ctrl+Cmd, `8` no Cmd. It needs its own Accessibility permission. Giving it to your terminal may not help: if your shell runs inside a multiplexer server such as Herdr, macOS treats that server, not the terminal app, as responsible.

Apps also often have link schemes, which are more reliable than clicking UI. The ChatGPT/Codex app answers `codex://dots`, `codex://threads/<id>` (a specific chat), `codex://settings`, and more:

```sh
grep -aoE 'codex://[A-Za-z0-9/_.?=&-]+' /Applications/ChatGPT.app/Contents/Resources/app.asar | sort -u
```

## Why some remote buttons are dead

The remote's HID report descriptor declares three channels:

| Channel | Carries | Seen by macOS |
|---|---|---|
| Keyboard | arrows, Select | ✅ |
| Consumer control | mic, Home, Menu, media, volume | ✅ |
| Amazon vendor (usage page `0xFF00`) | an 80-byte voice audio report and two 3-byte reports | Silent |

Back, TV and the four app buttons appear to go over the vendor channel, which never sends anything on a Mac, not even in Karabiner-EventViewer's raw view. A Fire TV presumably sends a handshake that enables it. For the same reason, the remote's own microphone never shows up as an audio device.
