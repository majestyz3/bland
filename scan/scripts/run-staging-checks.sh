#!/usr/bin/env bash
# Start Bland's staging check run for the Terraform-managed agent and print
# per-judge verdicts. Uses the documented Check Runs API only.
# Usage: scripts/run-staging-checks.sh [agent_id] [version_id]
#        (defaults read from `terraform output`)
set -euo pipefail
: "${BLAND_API_KEY:?Set BLAND_API_KEY first}"
API="${BLAND_BASE_URL:-https://api.bland.ai}"
cd "$(dirname "$0")/.."
AGENT="${1:-$(terraform output -raw agent_id)}"
VERSION="${2:-$(terraform output -raw version_id)}"
H=(-H "authorization: ${BLAND_API_KEY}" -H "content-type: application/json")

echo "Starting staging checks for agent $AGENT, version $VERSION"
START=$(curl -sS "${H[@]}" -X POST "$API/v2/agents/$AGENT/environments/staging/check-runs" -d "{\"version_id\":\"$VERSION\"}")
RUN=$(echo "$START" | jq -r '.data.id // empty')
STATUS=$(echo "$START" | jq -r '.data.status // empty')
[ -n "$RUN" ] || { echo "Could not start run:"; echo "$START" | jq .; exit 1; }
[ "$STATUS" != "ERROR" ] || { echo "Run could not be scheduled: $(echo "$START" | jq -r .data.error_message)"; exit 1; }

echo "Run $RUN started. Polling every ${POLL_SECONDS:-10}s (a run usually takes a few minutes)..."
while :; do
  OUT=$(curl -sS "${H[@]}" "$API/v2/agents/$AGENT/check-runs/$RUN")
  STATUS=$(echo "$OUT" | jq -r '.data.status')
  case "$STATUS" in
    PASSED|FAILED|ERROR|CANCELLED) break ;;
    *) printf '  %s  %s\n' "$(date +%H:%M:%S)" "$STATUS"; sleep "${POLL_SECONDS:-10}" ;;
  esac
done

echo
echo "$OUT" | jq -r '.data.verdicts // [] | .[] | "\(if .passed then "PASS" elif .passed == false then "FAIL" else "N/A " end)  \((if .required then "required" else "advisory" end) + "  ")\(((.match_rate // 0) * 100 | floor | tostring) + "%" | . + (" " * (5 - length)))  \(.name)"'
echo
echo "Run status: $STATUS   overall_passed: $(echo "$OUT" | jq -r '.data.overall_passed')"
[ "$STATUS" = "ERROR" ] && echo "Error: $(echo "$OUT" | jq -r .data.error_message)"
[ "$STATUS" = "PASSED" ]
