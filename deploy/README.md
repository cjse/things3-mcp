# Running things3-mcp on a Mac mini

This guide sets up a Mac mini that keeps Things 3 open, runs the MCP server
under launchd, and publishes it through Tailscale Funnel so Claude Code,
claude.ai, Claude Desktop, and the Claude mobile app can reach it.

AppleScript needs a logged-in GUI session. A pure SSH login is not enough.

## 1. Prepare the Mac

1. Sign in to Things 3 and Things Cloud with the account you want to manage.
2. System Settings > Users & Groups > turn on **Automatic login** for this user.
3. System Settings > General > Login Items > add **Things**.
4. Stop the Mac from sleeping:

   ```bash
   sudo pmset -a sleep 0 disksleep 0 displaysleep 10 disablesleep 1
   ```

5. Install Ruby 3.4.4 (this repo uses mise: `brew install mise && mise install`).
6. Clone this repo, then run `bundle install`.

Things opens automatically when the first AppleScript command arrives, but only
inside the logged-in session. Keep the user logged in.

## 2. Configure the server

```bash
cp .env.example .env
openssl rand -base64 32   # use as MCP_LOGIN_PASSWORD
openssl rand -base64 32   # use as MCP_AUTH_TOKEN (optional, Claude Code shortcut)
```

Set `MCP_PUBLIC_URL` to the public HTTPS URL that Tailscale will serve, for
example `https://macmini.tail1234.ts.net`. The OAuth issuer and the MCP resource
URL (`MCP_PUBLIC_URL/mcp`) derive from it, so it must match what clients type.

Check the server by hand before you install the agent:

```bash
bin/things3-mcp-http
curl -i http://127.0.0.1:9292/mcp        # expect 401 with a WWW-Authenticate header
```

## 3. Install the launchd agent

```bash
sed "s#/Users/YOU/things3-mcp#$(pwd)#g; s#/Users/YOU#$HOME#g" deploy/com.things3mcp.http.plist \
  > ~/Library/LaunchAgents/com.things3mcp.http.plist
mkdir -p log
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.things3mcp.http.plist
launchctl kickstart -k gui/$(id -u)/com.things3mcp.http
tail -f log/http.log
```

To stop it: `launchctl bootout gui/$(id -u)/com.things3mcp.http`.

## 4. Publish with Tailscale Funnel

1. Install Tailscale on the Mac mini and sign in.
2. In the Tailscale admin console, allow Funnel for this node (Access controls,
   `nodeAttrs` with `"attr": ["funnel"]`), and turn on HTTPS certificates.
3. Publish the local port:

   ```bash
   tailscale funnel --bg 9292
   tailscale funnel status
   ```

Puma still listens on 127.0.0.1 only. Tailscale terminates TLS and forwards to
it. The public URL is `https://<machine>.<tailnet>.ts.net`, which must equal
`MCP_PUBLIC_URL`.

If you only need access from your own devices, use `tailscale serve --bg 9292`
instead of `funnel`. claude.ai cannot reach a tailnet-only server.

## 5. Connect clients

Claude Code, with OAuth:

```bash
claude mcp add --transport http things https://macmini.tail1234.ts.net/mcp
```

Claude Code, with the static token (no browser step):

```bash
claude mcp add --transport http things https://macmini.tail1234.ts.net/mcp \
  --header "Authorization: Bearer $MCP_AUTH_TOKEN"
```

claude.ai, Claude Desktop, and the mobile app: Customize > Connectors > Add
custom connector. Enter `https://macmini.tail1234.ts.net/mcp`. Keep
authentication on "Always required" and let Claude register a client
automatically. On connect, a small page asks for `MCP_LOGIN_PASSWORD`.

## What is exposed

- `/.well-known/*`, `/register`, `/authorize`, `/token`: the OAuth endpoints.
- `/mcp`: the MCP endpoint. Every request needs a valid OAuth access token or
  the static token. No data path is reachable without a token.
- `data/oauth.json` holds registered clients and SHA-256 hashes of tokens. Back
  it up with the Mac if you want connections to survive a rebuild.
