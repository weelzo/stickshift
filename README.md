<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
    <img src="assets/logo-light.svg" alt="Stickshift" width="380">
  </picture>
</p>

<p align="center"><b>Turn a $20 Fire TV remote into your Mac's controller: talk to your terminal, drive your AI agents, and control your apps, all from the couch.</b></p>

Press the mic button to dictate anywhere. Hold Menu to talk to **kaza**, a small dispatcher agent that runs your terminal agents ("tell reviewer to give me a status", "open a new Codex next to the api tab and ask it to review PR 123"). The other buttons paste, delete, cancel, scroll, switch apps and run your meetings. Every button is one Karabiner rule you can change.

## Stickshift vs Codex Micro

Codex Micro, OpenAI's macro pad for Codex, showed that agents deserve physical buttons. Stickshift gets you most of that with a remote you may already own.

| | Codex Micro | Stickshift |
|---|---|---|
| Price | $230, limited run | The Fire TV remote you already own (about $20 new) |
| Controls | 13 keys, joystick, dial, touch control | 15 usable buttons, including the direction ring |
| Push-to-talk | ✅ | ✅ mic button |
| Works with | The Codex desktop app, keys remappable | Terminal agents (Claude Code, Codex CLI), the ChatGPT/Codex and Claude desktop apps, and any Mac app |
| Voice commands to agents | | ✅ kaza: "go to the docs tab", "tell reviewer to …", "what's waiting on me" |
| Status of your agents | RGB lights per chat | Spoken: hold Mute |
| Changing a button | Its own settings | One rule in `karabiner/rules.json` |

Codex Micro facts from launch coverage: [The Next Web](https://thenextweb.com/news/openai-codex-micro-hardware-work-louder), [New Atlas](https://newatlas.com/computers/openai-codex-micro-keyboard/), [Tom's Hardware](https://www.tomshardware.com/peripherals/keyboards/openais-first-hardware-device-is-an-rgb-macropod-codex-micro-features-13-low-profile-keys-and-a-joystick-for-controlling-ai-coding-agents).

## Quick start

```sh
git clone https://github.com/weelzo/stickshift.git && cd stickshift
./install.sh remote        # or: dictation, or: full
```

| Level | Needs | You get |
|---|---|---|
| `remote` | [Karabiner-Elements](https://karabiner-elements.pqrs.org) | Paste, delete, Enter, Esc, scrolling, app switcher, meeting and app controls |
| `dictation` | + a dictation app, by default [Handy](https://handy.computer) | The mic button starts and stops dictation |
| `full` | + [Herdr](https://herdr.dev), [Claude Code](https://claude.com/claude-code), [Ghostty](https://ghostty.org) | kaza voice dispatcher, spoken "what's waiting on me" |

The installer **adds** its rules to your existing Karabiner setup (all named `Stickshift: …`) and backs up your config first. Re-running it is safe, and `./install.sh --uninstall` removes only Stickshift's rules.

Then, once:
1. **Approve Karabiner's driver:** System Settings › General › Login Items & Extensions › Driver Extensions › turn on **Karabiner-DriverKit-VirtualHIDDevice**. Also allow `karabiner_grabber` and `karabiner_observer` under Privacy & Security › **Input Monitoring**.
2. **Pair the remote:** unplug your Fire TV, open System Settings › Bluetooth, and hold **Home** for about 10 seconds. When **"AR"** appears, click Connect **right away** (pairing mode lasts about 30 seconds). Quit the Keyboard Setup Assistant that pops up.
3. **Dictation level:** in Handy, set the shortcut to **Left Option** and turn **Push to talk off**.

## Buttons

The same in every app, except in the apps listed in the next section.

| Button | Does |
|---|---|
| **Mic** | Press = start dictation, press again = stop |
| **Menu** (hold) | Talk to kaza: jumps to its tab, you speak, then press Select |
| **Select** | Enter |
| **Home** | Tap = paste. Double tap = paste an image into Claude Code. Hold = open the ChatGPT app's "Your dot" |
| **Rewind** / **Fast-forward** | Delete (hold repeats) |
| **Mute** | Tap = Esc. Hold = hear which agents are waiting on you |
| **Vol + / −** | Scroll up / down |
| **Play** | App switcher: pick an app with the arrows, Select opens it, Mute cancels |

Back, TV and the four app buttons can't be used on a Mac ([why](docs/extras.md#why-some-remote-buttons-are-dead)).

## Per-app behavior

When one of these apps is in front, a few buttons change. Everything else stays as above.

| App | Mic | Mute | Volume | Other |
|---|---|---|---|---|
| **Chrome** (Google Meet) | tap = dictation, **hold = push-to-talk** | **your Meet mic on/off** | real volume | Applies to all of Chrome: on other tabs, Mute bookmarks the page |
| **Zoom** | tap = dictation, **hold = push-to-talk** | **your mic on/off** | real volume | Needs Zoom › Settings › Audio › "Press and hold Space key to temporarily unmute" |
| **ChatGPT / Codex app** | the app's **own dictation** | | | Up / Down = previous / next chat, Select = send, **hold Select = new chat** |
| **Claude app** | the app's **own dictation** | | | Up / Down = previous / next chat, Select = send, **hold Select = new chat** |
| **Keynote** | | black screen | | Rewind / Fast-forward = previous / next slide, Play = start the slideshow |

**ChatGPT / Codex app dictation setup:** ChatGPT › Settings › General › Dictation: set **Dictation shortcut = Off**, and under **Advanced** set **Single-tap shortcut = Right Command**. ChatGPT asks for Input Monitoring before it saves the shortcut.

**Claude app dictation:** works out of the box. The remote presses Claude's default dictation shortcut, **Command+D** (Claude › Settings › Dictation shortcut).

## kaza, the voice dispatcher (`full` level)

kaza is a Claude Code session in its own Herdr tab. Its `CLAUDE.md` turns it into a dispatcher: it matches spoken names against your Herdr agents and tabs, then focuses tabs, prompts agents, starts new Codex or Claude panes, or opens apps. It never answers another agent's approval prompt, never sends push, commit, deploy or delete, and confirms before closing anything.

```sh
herdr tab create --cwd ~/kaza --label kaza
herdr agent start kaza --kind claude --pane <root_pane id from the command above>
```

Accept the folder trust prompt, then type `/model haiku`, since a fast model is enough.

**Permissions:** the shipped `kaza/.claude/settings.json` pre-approves only reading, focusing, splitting panes, and opening five named apps. Claude Code asks you before kaza sends a prompt to an agent or starts a new one. For fully hands-free use, add `"Bash(herdr agent prompt:*)"` and `"Bash(herdr agent start:*)"` to `~/kaza/.claude/settings.json`. Know the trade-off: kaza reads other agents' output, and its instructions treat that text as data, not commands, but with those two permissions a tricked kaza could pass instructions on to other agents without asking you.

## Adding your own buttons

1. Open **Karabiner-EventViewer**, press the button, and click **Copy to pasteboard** to see what it sends.
2. Add a rule to `karabiner/rules.json`. Start its description with `Stickshift:` and add a `device_if` condition for vendor `369` / product `1071` so only the remote is affected.
3. Re-run `./install.sh`.

To find an app's shortcuts or links, see [MenuReader](docs/extras.md#menureader-find-any-apps-shortcuts).

## What runs where

Karabiner, the helper apps and the scripts run on your Mac. Handy transcribes locally. kaza is Claude Code, so its model runs in Anthropic's cloud. The ChatGPT app's dictation goes through OpenAI.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Buttons keep their default behavior (mic opens search, Play pauses media) | Karabiner's driver isn't approved yet (step 1 above) |
| "AR" never appears, or disappears before you can click | Hold Home again and click Connect immediately. Still nothing: hold Left + Menu + Back for 12 s to reset the remote |
| The app switcher appears but ignores the remote | Re-run `./install.sh --rebuild-helpers` |
| A helper app lost a permission | Rebuilding changes its signature: remove it from the permission list and add it again |

## Known issues

- **Fast-forward deletes one character, not a word,** in Ghostty.
- **The remote can wake the Mac from sleep** through Bluetooth activity. Take its batteries out at night, or turn Bluetooth off before sleep.
- **Double tap Home pastes the clipboard text first,** then the image.

## Extras

Personal add-ons, adjustable for your own setup: a [mic-off warning](docs/extras.md#mic-off-warning-installsh--boya) for wireless USB mics, [MenuReader](docs/extras.md#menureader-find-any-apps-shortcuts) for finding app shortcuts, and [hardware details](docs/extras.md#why-some-remote-buttons-are-dead). How it was built, including the dead ends: [JOURNEY.md](JOURNEY.md).

## License

[MIT](LICENSE)
