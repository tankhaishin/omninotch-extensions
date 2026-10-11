# Build for OmniNotch Live

Put anything in the Mac's notch: a build, a timer, a score, a deploy, a delivery. You write a small script that
prints JSON; OmniNotch draws it. No Swift, no SDK, no design work: every extension looks native because OmniNotch
does the drawing.

There are two ways in:

| | **Push** | **Extension** |
|---|---|---|
| What | Send an update when something happens | A script OmniNotch runs on a timer |
| Good for | Builds, deploys, long commands, other apps, Shortcuts | Anything you check: a countdown, CI status, a price |
| Setup | None | A folder with two files |

## Five-minute start

**1. Put the `omninotch` command on your PATH** (OmniNotch installs it the first time it runs):

```bash
mkdir -p ~/.local/bin && ln -sf "$HOME/Library/Application Support/OmniNotch/bin/omninotch" ~/.local/bin/omninotch
```

If `~/.local/bin` isn't on your PATH yet, add `export PATH="$HOME/.local/bin:$PATH"` to `~/.zshrc`.

**2. Push your first activity:**

```bash
omninotch push --id hello --title "Hello from my Mac" --value "hi" --icon sf:hand.wave
```

It appears in the closed notch and in the panel's **Live** tab. End it with `omninotch end --id hello`.

**3. Make an extension:**

```bash
omninotch new "Water"
```

This creates `~/Library/Application Support/OmniNotch/Extensions/local.water/` with a working extension: a
counter and an "Add one" button. OmniNotch notices the new folder at once and shows
*"Water is waiting to run · Allow…"* at the top of the Live tab. Press **Allow**.

**4. Edit `run`.** Change the title, the icon, what it counts. Save. Because the folder changed, OmniNotch asks
you to allow it again (that's the safety rule: you approve exactly the code that runs), then shows your change.

That's the whole loop.

## How an extension works

```
local.water/
  manifest.json   what it is, how often it runs, its settings and buttons
  run             any executable: zsh, bash, Python, Node, Swift… (chmod +x)
  icon.png        optional, 64 px, monochrome
```

```json
{
  "v": 1,
  "id": "local.water",
  "name": "Water",
  "description": "Glasses of water today.",
  "author": "Your Name",
  "run": "run",
  "every": "60s",
  "network": false,
  "settings": [
    { "key": "goal", "title": "Daily goal", "type": "text", "default": "8" }
  ],
  "actions": { "add": "Add one" }
}
```

OmniNotch runs `run` from the extension's folder every `every` (10 s at least; slower in power saving) and when
one of its buttons is pressed. It passes:

| Variable | What |
|---|---|
| `OMNINOTCH_SETTING_<KEY>` | Each setting's value, key in capitals (`OMNINOTCH_SETTING_GOAL`). Set them in Settings → Extensions |
| `OMNINOTCH_ACTION` | The pressed button's action name (`add`), or empty on a timed run |
| `OMNINOTCH_DATA` | A folder that's yours to keep state in. It survives updates and is never inside the extension folder, so writing to it doesn't trigger a new Allow |
| `OMNINOTCH_VERSION` | `1` |
| `PATH` | The system paths plus `/opt/homebrew/bin` and `/usr/local/bin` |

The script prints JSON to stdout, either a list of activities:

```json
[{ "v": 1, "id": "main", "title": "Water", "value": "3/8", "progress": 0.375, "icon": "sf:drop" }]
```

or a list plus when to run next (useful for a timer that should tick faster while it's running):

```json
{ "activities": [ … ], "next": "15s" }
```

Print an empty list `[]` to show nothing. Each run replaces everything the extension showed before.

**Limits:** 10 seconds per run, 64 KB of output, 5 activities per extension. A run that fails, times out or
prints bad JSON shows its error (and the first line of stderr) in Settings → Extensions, and its activities
disappear until the next good run.

**Buttons.** An activity's `actions` can hold up to two buttons. `{"title": "Add one", "run": "add"}` runs your
script with `OMNINOTCH_ACTION=add`; the name must be listed in the manifest's `actions`. `{"title": "Open",
"url": "https://…"}` opens a web page. Add `"confirm": true` to ask before running. A button can never run an
arbitrary command, only your own script.

**Trust.** OmniNotch fingerprints the extension folder. Nothing runs until you allow it, and any change to the
folder (including your own edits) asks again. Declare `"network": true` if your script uses the internet; the
Allow dialog says so.

## The activity

| Field | Required | Meaning | Limits |
|---|---|---|---|
| `v` | yes | Format version | `1` |
| `id` | yes | The same id updates the same activity | 64 chars, `A–Z a–z 0–9 . _ -` |
| `title` | yes | What it is | 40 chars |
| `subtitle` | no | One line of detail | 60 chars |
| `value` | no | The short thing worth a glance: a score, a price, time left | 8 chars |
| `progress` | no | `0` to `1`, or `"indeterminate"` | |
| `icon` | no | `sf:<SF Symbol name>` (browse them in Apple's SF Symbols app); `app:<bundle id>` for an installed app's own icon, like `app:com.google.Chrome` (find an id with `osascript -e 'id of app "Zoom"'`); or an image file in your extension folder | |
| `tint` | no | `calm` (default), `live`, `rising`, `alert` | |
| `state` | no | `active` (default), `needsYou`, `done`, `failed` | |
| `priority` | no | `low`, `normal` (default), `high` | |
| `actions` | no | Up to 2 buttons (see above) | 2 |
| `expires` | no | `"30s"`, `"10m"`, `"2h"`, `"1d"`, or an ISO date | 1 h by default; 10 s after `done` or `failed` |

End one early with `{"v": 1, "id": "main", "end": true}` (push) or by leaving it out of your next output
(extension).

**Which one shows in the closed notch:** anything that `needsYou`, then `high` priority, then the most recently
updated. Only one shows at a time, never rotating. The rest are in the Live tab.

**When it pops up beside the camera:** when an activity starts needing you, finishes (`done`), fails, or on any
update to a `high` priority one. Use `high` sparingly; it interrupts.

## Design rules

OmniNotch draws everything, so your job is the words and the state. Four rules keep the notch calm:

1. **`value` is a glance.** "3/8", "12d 4h", "+2.4%", "2–1". Not a sentence. If you have nothing short to say,
   leave it out; a progress ring or the title stands in.
2. **Say it in words, not colour.** The state already speaks: `failed` says "failed", `needsYou` says "needs you".
   Don't put "ERROR" in the title.
3. **`rising` (amber) is only for time.** A countdown, something due, something waiting on you. `alert` (red)
   is only for something broken. Most things are `calm`.
4. **`needsYou` means a person has to act.** Approve, answer, take the break. It jumps to the front and pops
   up, so it's not for news.

## Push from anything

**Command line.** Flags map one-to-one to the fields:

```bash
omninotch push --id deploy --title "Deploying web" --progress 0.4 --icon sf:hammer
omninotch push --id deploy --title "Deployed" --state done
omninotch end  --id deploy
omninotch push --json '{"v":1,"id":"deploy","title":"Deploying web","value":"40%"}'
```

`--source <name>` groups your activities (default `push`); `--button <title> --url <https://…>` adds a link
button. Exit code 0 means OmniNotch took it; otherwise the reason is on stderr (69 means OmniNotch isn't running).

**A link,** from Shortcuts, Automator, Raycast or any app: `omninotch://push?id=deploy&title=Deployed&state=done`
and `omninotch://end?id=deploy`. Links can add `url` buttons but never `run` buttons, since any web page can open
a link.

**A socket,** from your own app: connect to `~/Library/Application Support/OmniNotch/agent.sock` (private to your
user) and write one JSON line:

```json
{"type": "activity", "source": "my-app", "activity": {"v": 1, "id": "sync", "title": "Syncing", "progress": 0.5}}
```

The reply is `ok` or `error: <why>`.

## Recipes

**Python extension** (`run`, `chmod +x run`):

```python
#!/usr/bin/env python3
import json, os, pathlib
data = pathlib.Path(os.environ["OMNINOTCH_DATA"])
goal = int(os.environ.get("OMNINOTCH_SETTING_GOAL", "8"))
f = data / "count"
n = int(f.read_text()) if f.exists() else 0
if os.environ.get("OMNINOTCH_ACTION") == "add":
    n += 1
    f.write_text(str(n))
print(json.dumps([{"v": 1, "id": "main", "title": "Water", "value": f"{n}/{goal}",
                   "progress": min(1, n / goal), "icon": "sf:drop",
                   "actions": [{"title": "Add one", "run": "add"}]}]))
```

**Node extension:**

```js
#!/usr/bin/env node
fetch("https://api.github.com/repos/apple/swift").then(r => r.json()).then(r =>
  console.log(JSON.stringify([{ v: 1, id: "stars", title: "swift", icon: "sf:star",
    value: `${(r.stargazers_count / 1000).toFixed(1)}k` }])));
```

It uses the internet, so declare `"network": true`. Node 18 or later.

**Wrap any long command** with the push route. `samples/extensions/notch-run/notch-run` is a ready one:

```bash
notch-run make build      # shows "running", then "done" or "failed · exit code 2"
```

## Samples

In the OmniNotch repo under `samples/extensions/`:

- **pomodoro/**: a timer with Start and Stop buttons, state in `$OMNINOTCH_DATA`, faster runs while it's going
  (`next`), and a `needsYou` nudge when the break is due. Copy the folder into your Extensions folder to try it.
- **notch-run/**: the push wrapper above.

And the 30 that ship inside OmniNotch, in `Resources/Extensions/`: read any of them for a pattern. Good ones to
start with: **Countdown** (settings, `rising`), **Memory Hog** (a `confirm` button), **Homebrew** (a background job
with `indeterminate` progress), **Is It Up** (`failed` then `done`), and **Reminders** (JavaScript via `osascript`).

Check yours the way OmniNotch runs it: `tools/check-extension <folder> [--action <name>] [--set KEY=value]`.

## Testing and debugging

Run your script by hand with the same variables OmniNotch passes, and check the JSON:

```bash
cd ~/Library/Application\ Support/OmniNotch/Extensions/local.water
OMNINOTCH_DATA=/tmp/water OMNINOTCH_ACTION=add ./run | python3 -m json.tool
```

Then push it straight in to see how it looks, without waiting for the timer:

```bash
omninotch push --json "$(OMNINOTCH_DATA=/tmp/water ./run | python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)[0]))')"
```

If it doesn't show: check Settings → Extensions for its error, that `run` is executable (`chmod +x run`), that
the extension is on and allowed, and that it prints nothing but the JSON to stdout (send logs to stderr).

## Sharing

An extension is a folder, so share it as a zip or a git repo. Use a reverse-domain id you own
(`com.yourname.thing`); `local.` ids are for your own Mac. Whoever installs it allows it once on their Mac, and
again whenever it changes.

If your extension shows another company's data (Spotify, GitHub, a sports league), say in its description that
it's unofficial, and make sure their API terms allow it.
