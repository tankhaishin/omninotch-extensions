# Extension formats

Three kinds of extension live in this repo. All use `manifest.json`; the full runtime (the command bar, screens,
actions) is specified in OmniNotch's COMMANDS.md (v2) and EXTENSIONS.md (v1, Live statuses).

## 1. Script extensions (v1 Live, v2 commands)

A `run` script in any language that prints JSON: Live statuses (v1) and/or commands with list, detail and form
screens (v2). See [GUIDE.md](GUIDE.md).

## 2. Quicklinks (v2, no script)

A command can be just a link. `{query}` is replaced with what you type (percent-encoded); a link without it opens as is.

```json
{ "v": 2, "id": "com.mactoro.web-search", "name": "Web Search", "kind": "quicklinks", "category": "Web search",
  "commands": [
    { "id": "search-google", "title": "Search Google", "mode": "run",
      "url": "https://www.google.com/search?q={query}",
      "arguments": [{ "name": "query", "placeholder": "Search…", "required": true, "percentEncoded": true }] } ] }
```

Any scheme a Mac can open works (`https:`, `maps:`, `spotify:`, `dict:`, `macappstore:`); `file:` and
`javascript:` are refused. Our packs are generated from [tools/quicklinks.json](tools/quicklinks.json) by
`tools/build-quicklinks`; add a link there and open a pull request.

## 3. Script commands in Raycast's format (v2, `format: "raycast-script"`)

OmniNotch runs scripts written for Raycast's script-command format (`@raycast.title`, `@raycast.mode`, arguments,
`refreshTime`) unchanged. `extensions/script-commands/` holds the open-source collection from
[raycast/script-commands](https://github.com/raycast/script-commands) (MIT, see its LICENSE in that folder),
imported by `tools/import-script-commands` without running anything. Each manifest credits the script's own author,
links to its source at the imported commit, and lists what it needs (an app, a tool like `jq`, or an API key you
add to the script). Those scripts are by their authors; neither they nor Raycast made or endorse OmniNotch.

| Raycast mode | In OmniNotch |
|---|---|
| `silent`, `compact` | `run`: a short result in the bar |
| `fullOutput` | `view`: a detail screen with the output |
| `inline` + `refreshTime` | `live`: a Live status |

## Checking

`tools/check-extension <folder>` checks every kind. Script extensions are run the way OmniNotch runs them;
quicklinks and imported scripts are checked from their files only (imported scripts are never run by the checker).
