# Things3 MCP Server

A Model Context Protocol (MCP) server for Things 3 on macOS. It drives Things
through AppleScript, the official automation interface, so it cannot corrupt
your Things Cloud sync history. Run it locally over stdio, or on an always-on
Mac behind Tailscale with OAuth 2.1 so claude.ai and the Claude mobile app can
use it too.

Built with the official [`mcp`](https://github.com/modelcontextprotocol/ruby-sdk)
Ruby gem. Started from [things3-mcp-ruby](https://github.com/mattsafaii/things3-mcp-ruby)
by mattsafaii.

## Tools

Every tool returns structured JSON plus a short text summary. Tasks, projects,
areas, and tags can be addressed by id or by exact name.

| Tool | What it does |
|---|---|
| `get_tasks` | List tasks by built-in list (inbox, today, tomorrow, anytime, upcoming, someday, logbook, trash, all), project, area, tag, name search, or status |
| `get_task` | One task with all fields |
| `add_task` | Create a task with notes, project or area, list, tags, deadline, and start date |
| `update_task` | Change title, notes, project, area, list, tags, dates, or status |
| `complete_task` | Mark a task completed |
| `delete_task` | Move a task to the Trash |
| `move_task` | Move a task to a project, an area, or a built-in list |
| `get_projects` | List projects by area, status, tag, or name search |
| `get_project` | One project with its open tasks |
| `add_project`, `update_project`, `delete_project` | Manage projects |
| `get_areas`, `add_area`, `update_area`, `delete_area` | Manage areas |
| `get_tags`, `add_tag`, `update_tag`, `delete_tag` | Manage tags, including parent tags |

Dates accept natural language ("tomorrow", "next friday", "in 2 weeks") or
`YYYY-MM-DD`. A start date also accepts `someday`, `anytime`, and `none`.

### Limits of the AppleScript interface

- Checklist items and headings are not readable or writable.
- A deadline cannot be cleared once set. A project cannot be removed from its area.
- The Mac must have a logged-in GUI session. Things opens on demand.

## Requirements

- macOS with Things 3
- Ruby 3.4.4 (`.ruby-version`), Bundler

```bash
bundle install
```

## Local use over stdio

```bash
claude mcp add things -- /path/to/things3-mcp/bin/things3-mcp-stdio
```

Or point any MCP client at `bin/things3-mcp-stdio`.

## Remote use over HTTP

`bin/things3-mcp-http` runs Puma on `127.0.0.1:9292` with:

- MCP Streamable HTTP at `/mcp`
- OAuth 2.1 (PKCE, dynamic client registration, refresh token rotation) at
  `/.well-known/*`, `/register`, `/authorize`, and `/token`, guarded by one
  password (`MCP_LOGIN_PASSWORD`)
- an optional static bearer token (`MCP_AUTH_TOKEN`) for Claude Code

Copy `.env.example` to `.env` and fill it in. Then see
[deploy/README.md](deploy/README.md) for the Mac mini, launchd, and Tailscale
Funnel setup, and for connecting Claude Code and claude.ai.

## Development

```bash
bundle exec rspec
THINGS3_MCP_DEBUG=1 bin/things3-mcp-stdio   # logs every AppleScript to stderr
```

Layout:

- `lib/things3_mcp/applescript/generator/` builds AppleScript. Records come
  back as delimited text and `RecordParser` turns them into hashes.
- `lib/things3_mcp/applescript/executor.rb` runs `osascript` under one lock
  with a timeout.
- `lib/things3_mcp/client.rb` is the Ruby API the tools call.
- `lib/things3_mcp/tools/` holds one `MCP::Tool` per tool.
- `lib/things3_mcp/oauth/` and `lib/things3_mcp/http/` hold the HTTP server.

## License

MIT
