# Sharing an extension

1. Fork this repo and add your folder at `extensions/<your GitHub username>/<name>/` (lowercase, digits, `-`).
2. In `manifest.json`, set `"id": "<your GitHub username>.<name>"`, plus `description` (one line, about 45
   characters), `category` (`Mac`, `Time`, `Work` or `Developer`) and `example` (an activity showing what it looks
   like, for the store).
3. Check it the way OmniNotch runs it: `tools/check-extension extensions/<you>/<name>` (add `--set KEY=value` for
   settings, `--action <name>` for buttons).
4. Open a pull request. The check runs automatically; then a person reads your script before it goes live.

## What we accept

- It does what its description says, and nothing else. No tracking, no analytics, no sending data anywhere it
  doesn't need to go.
- `"network": true` if it uses the internet at all.
- No secrets in the folder. Tokens and keys go in settings, typed by the person who installs it.
- It stays quiet when there's nothing to say (print `[]`), and it follows the design rules in GUIDE.md.
- If it uses another company's service: say "for <Service>" in the description, don't use their logo as the icon,
  and make sure their API terms allow it.
- Each update is reviewed again. Everyone who installed it is asked to allow the new version.

By contributing you agree your extension is released under the MIT licence.
