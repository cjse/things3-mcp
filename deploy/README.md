# Running things3-mcp as a service

This guide runs the HTTP server under launchd on a Mac that keeps Things 3
open, and puts a TLS-terminating proxy in front of it so Claude Code, claude.ai,
Claude Desktop, and the Claude mobile app can reach it.

AppleScript needs a logged-in GUI session. A pure SSH login is not enough. Turn
on automatic login for the user that runs Things, and keep that user logged in.
Things opens on its own when the first AppleScript command arrives.

## 1. Set up

As the user that runs Things:

```bash
git clone https://github.com/cjse/things3-mcp.git ~/things3-mcp
cd ~/things3-mcp
bin/setup --public-url https://things.example.com
```

`bin/setup` installs Ruby through mise if mise is present, installs the gems,
writes `.env` with a fresh login password and static token, installs the
launchd agent, starts it, and makes one `get_areas` call. That first call makes
macOS show an Automation prompt for Things. Click Allow.

Store the two secrets it prints in your password manager. Run it again any
time; it keeps an existing `.env`.

The public URL must be the one clients will type. The OAuth issuer and the MCP
resource URL (`MCP_PUBLIC_URL/mcp`) derive from it. To change it later, edit
`.env` and run `bin/restart`.

## 2. Manage

| Command | What it does |
|---|---|
| `bin/status` | Agent, local port, public URL, Things. Exit 1 if anything is down |
| `bin/check` | Calls `get_areas` through the server with the static token |
| `bin/logs` | Follows `log/http.log` |
| `bin/restart` | After a `git pull` or an `.env` change |
| `bin/stop`, `bin/start` | Unload and load the agent |
| `bin/uninstall` | Removes the agent. `--purge` also deletes `.env`, `data/`, and `log/` |

## 3. Put a TLS proxy in front

Puma listens on `127.0.0.1:9292` only. Any proxy that terminates TLS and
forwards to that port works. Two that need no open router port:

- Cloudflare Tunnel: `cloudflared tunnel --url http://localhost:9292` for a
  quick test, or a named tunnel with an ingress rule for your hostname. Works
  behind CGNAT.
- Tailscale Funnel: `tailscale funnel --bg 9292`. The public URL is
  `https://<machine>.<tailnet>.ts.net`.

## 4. Connect clients

Claude Code, with OAuth:

```bash
claude mcp add --transport http things https://things.example.com/mcp
```

Claude Code, with the static token (no browser step):

```bash
claude mcp add --transport http things https://things.example.com/mcp \
  --header "Authorization: Bearer $MCP_AUTH_TOKEN"
```

claude.ai, Claude Desktop, and the mobile app: Customize > Connectors > Add
custom connector. Enter `https://things.example.com/mcp`. Keep authentication
on "Always required" and let Claude register a client automatically. On
connect, a small page asks for `MCP_LOGIN_PASSWORD`.

## What is exposed

- `/.well-known/*`, `/register`, `/authorize`, `/token`: the OAuth endpoints.
- `/mcp`: the MCP endpoint. Every request needs a valid OAuth access token or
  the static token. No data path is reachable without a token.
- `data/oauth.json` holds registered clients and SHA-256 hashes of tokens. Back
  it up with the Mac if you want connections to survive a rebuild.
