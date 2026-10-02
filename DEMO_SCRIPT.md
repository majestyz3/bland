# Terraform demo script (bonus segment, about 3 minutes)

Only run this if you're ahead of time. The dashboard demo is the main event.

## Setup line

"I built the SCAN agent in the UI first to learn the platform. Then I asked how a platform team would manage fifty of these, so I wrote a Terraform provider against Bland's current public API. This repo uses it to stand up the same agent from scratch."

## Sequence

1. Show `scan/` in the editor: `agent.tf`, `judges.tf`, `gate.tf`, `release.tf`. One line each.
2. Show the already-applied result: `terraform output`, then open the `dashboard.canvas` link. Same five-step agent, created by code.
3. The change: `terraform plan -var 'release_note=v1.1 tighter benefits wording'`. Point out that only the version and the staging release change.
4. Apply it (or show the pre-run apply), then `bash scripts/run-staging-checks.sh`. Narrate the per-judge verdicts as they land.
5. Open Environments: "Terraform stages it, Bland's judges gate it, and a person promotes it. I deliberately left production promotion out of the default flow."

## Lines worth having ready

- "The UI is where you build. Terraform is where you standardize and review."
- "Agent versions are immutable in Bland's API, so every change is a new version. That maps cleanly onto Terraform."
- "Nothing in here can buy a number, place a call, or promote to production by default."
- If asked who wrote it: "I designed it and tested it; I used an AI coding assistant heavily for the Go, same as I'd expect your engineers to."

## Recovery

- Apply fails live: switch to the dashboard-built agent. Everything you need to show already exists there.
- Check run hangs: open Evaluations, Runs, and show the existing CI run from the dashboard agent.
