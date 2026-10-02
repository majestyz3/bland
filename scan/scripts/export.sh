#!/usr/bin/env bash
# Read-only export of the dashboard-built SCAN demo agent, so the Terraform
# generator works from real API shapes instead of guesses.
# Usage:  export BLAND_API_KEY=...   then   ./export.sh
# Nothing here creates, changes, or deletes anything in Bland.
set -euo pipefail
: "${BLAND_API_KEY:?Set BLAND_API_KEY first (never commit it)}"
command -v jq >/dev/null || { echo "jq is required"; exit 1; }

API="https://api.bland.ai"
SRC_AGENT="c6cf39fb-724c-463c-ba02-2a08f86b324d"   # dashboard-built "SCAN Member Services" agent
H=(-H "authorization: ${BLAND_API_KEY}")
OUT="$(cd "$(dirname "$0")/.." && pwd)/exports"
mkdir -p "$OUT/judges"

get() { curl -sS --fail-with-body "${H[@]}" "$API$1"; }

echo "1/6 agent snapshot (latest saved version)"
get "/v2/agents/$SRC_AGENT/versions/latest" | jq . > "$OUT/agent_latest.json"

echo "2/6 environments and staging checks"
get "/v2/agents/$SRC_AGENT/environments" | jq . > "$OUT/environments.json"
get "/v2/agents/$SRC_AGENT/environments/staging/checks" | jq . > "$OUT/staging_checks.json"

echo "3/6 test scenarios"
get "/v1/agent-testing/scenarios" | jq . > "$OUT/scenarios.json"

echo "4/6 judges (eval agents) and their published versions"
get "/v1/evals/agents" | jq . > "$OUT/judges/list.json"
jq -r '[.. | objects | select(has("id") and has("name")) | select((.name|type)=="string" and (.name|test("^J[1-5] ")))] | unique_by(.id) | .[] | .id' \
  "$OUT/judges/list.json" | while read -r JID; do
  get "/v1/evals/agents/$JID" | jq . > "$OUT/judges/agent_$JID.json"
  # published version id field name varies by response; take the first non-null candidate
  VID=$(jq -r '[.. | objects | (.active_version_id?, .published_version_id?)] | map(select(. != null)) | first // empty' "$OUT/judges/agent_$JID.json")
  if [ -n "$VID" ]; then
    get "/v1/evals/agents/$JID/versions/$VID" | jq . > "$OUT/judges/version_$JID.json"
  fi
done

echo "5/6 alarms"
get "/v1/alarms" | jq . > "$OUT/alarms.json"

echo "6/6 tools in the library (for reference only)"
get "/v2/tools" | jq . > "$OUT/tools.json" 2>/dev/null || echo '{"note":"tools list endpoint unavailable"}' > "$OUT/tools.json"

# Safety: make sure no API key slipped into the exports
if grep -rq "${BLAND_API_KEY}" "$OUT"; then echo "API key found in exports, aborting"; rm -rf "$OUT"; exit 1; fi
echo "Done. Review exports/ before committing. Files:"; find "$OUT" -type f | sort
