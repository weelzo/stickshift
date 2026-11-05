#!/usr/bin/python3 -I
"""Merge Stickshift's Karabiner rules into the user's existing Karabiner config.

Only rules whose description starts with "Stickshift:" are ever added or removed, so the
user's own rules, devices and profiles are left alone. A timestamped backup is written first.

  install_rules.py --level remote|dictation|full [--boya] [--chatgpt] [--claude-app]
  install_rules.py --uninstall
  install_rules.py --self-test
"""
import argparse, copy, json, os, shutil, sys, time

PREFIX = "Stickshift:"
HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.path.expanduser("~/.config/karabiner/karabiner.json")
LEVELS = {"remote": set(), "dictation": {"dictation"}, "full": {"dictation", "full"}}
# Whole rules that only make sense with a component installed.
RULE_NEEDS = {
    "Stickshift: ChatGPT:": "chatgpt",
    "Stickshift: Claude app:": "claudeapp",
    "Stickshift: hold Menu": "full",
    "Stickshift: press mic": "dictation",
}
SLOTS = ("to", "to_if_alone", "to_if_held_down", "to_after_key_up")


def event_needs(ev):
    """Which optional component a single output event depends on (None = always available)."""
    sc = ev.get("shell_command", "")
    if "BoyaCheck" in sc:
        return "boya"
    if "herdr" in sc or "waiting.py" in sc:
        return "full"
    if "codex://" in sc:
        return "chatgpt"
    if ev.get("key_code") == "left_option":  # Handy's default shortcut
        return "dictation"
    return None


def meaningful(events):
    return any(ev.get("key_code") != "vk_none" for ev in events)


def filter_rules(rules, enabled):
    out = []
    for rule in rules:
        need = next((n for p, n in RULE_NEEDS.items() if rule["description"].startswith(p)), None)
        if need and need not in enabled:
            continue
        kept = []
        for m in rule["manipulators"]:
            m = copy.deepcopy(m)
            for slot in SLOTS:
                if slot in m:
                    m[slot] = [ev for ev in m[slot] if event_needs(ev) in (None, *enabled)]
                    if not m[slot]:
                        del m[slot]
            if any(meaningful(m.get(s, [])) for s in ("to", "to_if_alone", "to_if_held_down")):
                kept.append(m)
        if kept:
            out.append({**rule, "manipulators": kept})
    return out


def load_rules(home, brew):
    text = open(os.path.join(HERE, "rules.json")).read()
    rules = json.loads(text)["rules"]

    def sub(x):
        if isinstance(x, str):
            return x.replace("__HOME__", home).replace("__BREW__", brew)
        if isinstance(x, list):
            return [sub(i) for i in x]
        if isinstance(x, dict):
            return {k: sub(v) for k, v in x.items()}
        return x
    return sub(rules)


def selected_profile(cfg):
    profiles = cfg.setdefault("profiles", [])
    if not profiles:
        profiles.append({"name": "Default profile", "selected": True,
                         "virtual_hid_keyboard": {"keyboard_type_v2": "ansi"}})
    return next((p for p in profiles if p.get("selected")), profiles[0])


def write_config(cfg):
    os.makedirs(os.path.dirname(CONFIG), exist_ok=True)
    if os.path.exists(CONFIG):
        backup = f"{CONFIG}.bak.{int(time.time())}"
        shutil.copy2(CONFIG, backup)
        print(f"Backed up your Karabiner config to {backup}")
    tmp = CONFIG + ".tmp"
    with open(tmp, "w") as f:
        json.dump(cfg, f, indent=2)
    os.replace(tmp, CONFIG)


def merge(level, boya, chatgpt, claudeapp, home, brew):
    enabled = (LEVELS[level] | ({"boya"} if boya else set()) | ({"chatgpt"} if chatgpt else set())
               | ({"claudeapp"} if claudeapp else set()))
    ours = filter_rules(load_rules(home, brew), enabled)
    cfg = json.load(open(CONFIG)) if os.path.exists(CONFIG) else {}
    cm = selected_profile(cfg).setdefault("complex_modifications", {})
    others = [r for r in cm.get("rules", []) if not r.get("description", "").startswith(PREFIX)]
    cm["rules"] = ours + others  # ours first: app-specific Stickshift rules must win
    write_config(cfg)
    print(f"Installed {len(ours)} Stickshift rules ({level}{', boya' if boya else ''}"
          f"{', chatgpt' if chatgpt else ''}{', claude app' if claudeapp else ''}); kept {len(others)} of your own rules.")


def uninstall():
    if not os.path.exists(CONFIG):
        print("No Karabiner config found, nothing to remove.")
        return
    cfg = json.load(open(CONFIG))
    removed = 0
    for p in cfg.get("profiles", []):
        rules = p.get("complex_modifications", {}).get("rules", [])
        keep = [r for r in rules if not r.get("description", "").startswith(PREFIX)]
        removed += len(rules) - len(keep)
        if rules:
            p["complex_modifications"]["rules"] = keep
    write_config(cfg)
    print(f"Removed {removed} Stickshift rules. Your own rules are untouched.")


def self_test():
    rules = load_rules("/H", "/B")
    dump = lambda rs: json.dumps(rs)
    remote = filter_rules(rules, LEVELS["remote"])
    full = filter_rules(rules, LEVELS["full"] | {"boya", "chatgpt", "claudeapp"})
    assert all(r["description"].startswith(PREFIX) for r in rules), "every rule needs the prefix"
    events = [ev for r in remote for m in r["manipulators"] for s in SLOTS for ev in m.get(s, [])]
    assert not any(ev.get("key_code") == "left_option" for ev in events), "remote level must not trigger Handy"
    assert "herdr" not in dump(remote) and "BoyaCheck" not in dump(remote) and "codex://" not in dump(remote)
    assert any(r["description"].startswith("Stickshift: hold Menu") for r in full), "full level has kaza"
    assert len(full) == len(rules), "full level with all options keeps every rule"
    assert "__HOME__" not in dump(rules) and "__BREW__" not in dump(rules)
    print(f"self-test ok: remote={len(remote)} rules, full={len(full)} rules")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--level", choices=LEVELS, default="remote")
    ap.add_argument("--boya", action="store_true")
    ap.add_argument("--chatgpt", action="store_true")
    ap.add_argument("--claude-app", action="store_true")
    ap.add_argument("--uninstall", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    brew = os.environ.get("STICKSHIFT_BREW", "/opt/homebrew")
    if a.self_test:
        self_test()
    elif a.uninstall:
        uninstall()
    else:
        merge(a.level, a.boya, a.chatgpt, a.claude_app, os.path.expanduser("~"), brew)
    sys.exit(0)
