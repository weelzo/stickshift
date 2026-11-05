#!/usr/bin/python3 -I
"""Say out loud which Herdr agents are waiting on me (blocked or done). Run by holding Mute on the remote."""
import json, subprocess

try:
    out = subprocess.run(["__BREW__/bin/herdr", "agent", "list"],
                         capture_output=True, text=True, timeout=5).stdout
    agents = json.loads(out)["result"]["agents"]
except (OSError, subprocess.TimeoutExpired, ValueError, KeyError):
    subprocess.run(["say", "Herdr is not reachable."])
    raise SystemExit(1)

def name(a):
    title = (a.get("terminal_title_stripped") or "").split("|")[0].strip()
    return a.get("name") or title[:40] or a["pane_id"]

waiting = [a for a in agents if a["agent_status"] in ("blocked", "done")]
if not waiting:
    text = "Nothing is waiting on you."
else:
    parts = [f"{name(a)} is {'asking you something' if a['agent_status'] == 'blocked' else 'done'}" for a in waiting[:5]]
    text = f"{len(waiting)} waiting. " + ". ".join(parts) + "."
subprocess.run(["say", text])
