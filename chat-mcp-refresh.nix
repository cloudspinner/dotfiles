# Workaround for Claude Code not requesting offline access from Google
# (github.com/anthropics/claude-code/issues/35092): Google only issues OAuth
# refresh tokens when the authorization request carries access_type=offline,
# which Claude Code's MCP client never sends, so its google-chat token dies
# after an hour. We minted our own refresh token (stored imperatively in
# ~/.local/state/chat-mcp/refresh_token, chmod 600) and this module exchanges
# it for a fresh access token every 40 minutes, patching the result into
# Claude Code's credential store.
# Remove once Claude Code implements MCP refresh tokens (SEP-2207).
{ pkgs, ... }:

let
  chat-mcp-refresh = pkgs.writeShellScriptBin "chat-mcp-refresh" ''
    set -euo pipefail
    PATH=${pkgs.jq}/bin:${pkgs.curl}/bin:${pkgs.coreutils}/bin
    CRED=$HOME/.claude/.credentials.json
    CFG=$HOME/.claude.json
    RT_FILE=$HOME/.local/state/chat-mcp/refresh_token
    [ -f "$RT_FILE" ] || { echo "no refresh token at $RT_FILE" >&2; exit 1; }
    KEY=$(jq -r '.mcpOAuth | keys[] | select(startswith("google-chat|"))' "$CRED")
    [ -n "$KEY" ] || { echo "no google-chat entry in $CRED" >&2; exit 1; }
    CID=$(jq -r '.mcpServers["google-chat"].oauth.clientId' "$CFG")
    CSEC=$(jq -r --arg k "$KEY" '.mcpOAuthClientConfig[$k].clientSecret' "$CRED")
    RESP=$(curl -sf -X POST https://oauth2.googleapis.com/token \
      --data-urlencode client_id="$CID" \
      --data-urlencode client_secret="$CSEC" \
      --data-urlencode grant_type=refresh_token \
      --data-urlencode refresh_token="$(cat "$RT_FILE")")
    AT=$(echo "$RESP" | jq -r '.access_token // empty')
    EXP=$(echo "$RESP" | jq -r '.expires_in // 3600')
    [ -n "$AT" ] || { echo "refresh failed: $RESP" >&2; exit 1; }
    EXPAT=$(( ($(date +%s) + EXP - 300) * 1000 ))
    TMP=$(mktemp "$CRED.XXXXXX")
    jq --arg k "$KEY" --arg at "$AT" --argjson ex "$EXPAT" \
      '.mcpOAuth[$k].accessToken = $at | .mcpOAuth[$k].expiresAt = $ex' "$CRED" > "$TMP"
    chmod 600 "$TMP"
    mv "$TMP" "$CRED"
    echo "google-chat token refreshed, expires $(date -d @$(( EXPAT / 1000 )))"
  '';
in
{
  home.packages = [ chat-mcp-refresh ];

  systemd.user.services.chat-mcp-refresh = {
    Unit.Description = "Refresh Google Chat MCP access token for Claude Code";
    Service = {
      Type = "oneshot";
      ExecStart = "${chat-mcp-refresh}/bin/chat-mcp-refresh";
    };
  };

  systemd.user.timers.chat-mcp-refresh = {
    Unit.Description = "Refresh Google Chat MCP access token every 40 minutes";
    Timer = {
      OnStartupSec = "2min";
      OnUnitActiveSec = "40min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
