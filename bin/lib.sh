# Shared by the bin/ service scripts. Source it, do not run it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="com.things3mcp.http"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SERVICE="gui/$(id -u)/$LABEL"
ENV_FILE="$ROOT/.env"
LOG_FILE="$ROOT/log/http.log"

# The agent and these scripts find Ruby the same way: version-manager shims first.
export PATH="$HOME/.local/share/mise/shims:$HOME/.rbenv/shims:/opt/homebrew/bin:/usr/local/bin:$PATH"

say() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

env_get() { { grep -E "^$1=" "$ENV_FILE" 2>/dev/null || true; } | head -1 | cut -d= -f2-; }
port() { local p; p="$(env_get PORT)"; echo "${p:-9292}"; }
public_url() { local u; u="$(env_get MCP_PUBLIC_URL)"; echo "${u:-http://127.0.0.1:$(port)}"; }
local_url() { echo "http://127.0.0.1:$(port)"; }

agent_loaded() { launchctl print "$SERVICE" &>/dev/null; }
agent_pid() { { launchctl print "$SERVICE" 2>/dev/null || true; } | awk '$1 == "pid" { print $3 }'; }

http_code() { curl -s -o /dev/null -m "${2:-5}" -w '%{http_code}' "$1" 2>/dev/null || true; }

wait_for_server() {
  local i
  for i in $(seq 1 30); do
    [ "$(http_code "$(local_url)/mcp")" = 401 ] && return 0
    sleep 1
  done
  return 1
}

write_plist() {
  mkdir -p "$(dirname "$PLIST")" "$ROOT/log"
  sed "s#/Users/YOU/things3-mcp#$ROOT#g; s#/Users/YOU#$HOME#g" "$ROOT/deploy/$LABEL.plist" > "$PLIST"
}
