# scan/: the SCAN demo agent, fully in Terraform

This module creates a **brand-new** Bland V2 agent, `SCAN Member Services (Terraform)`, that behaves the same as the dashboard-built demo agent, plus everything around it:

| Resource | Count | Notes |
|---|---|---|
| `bland_agent` | 1 | New agent; the dashboard agent is never touched |
| `bland_knowledge_base` | 1 | `content/kb_scan_demo_member_benefits.txt`, waits for COMPLETED |
| `bland_agent_version` | 1 | Built from the exported dashboard snapshot (see below) |
| `bland_eval_agent` + version config + publish | 5 each | Judges J1 to J5, rubric text from `content/judges.json` |
| `bland_agent_test_scenario` | 6 | Tests A to F, agent-targeted |
| `bland_agent_checks` | 1 | Staging gate: Tests A to E, J1 to J4 required, J5 advisory, 1 conversation each |
| `bland_agent_release` | 1 | Publishes the version to staging (triggers the gate) |
| `bland_agent_promotion` | 0 | Only if `enable_promotion = true` |
| `bland_alarm` | 0 | Only if `create_alarm = true` (org-level) |

Nothing here buys numbers, binds inbound numbers, places calls, sends SMS, or transfers to a real person. The escalation number defaults to the fictional `+12025550100`.

## How the agent config gets here

The agent's behavior (Call Start disclosure, auth zone, pathways 03/04/05, guardrails, embedded tools, memory off) lives in one versioned snapshot. Rather than hand-write that JSON, the module reads the snapshot exported from the dashboard-built agent and transforms it:

- attaches the new knowledge base instead of the old one
- sets the new display name
- forces `contact.inboundNumbers = []`
- rewrites the synthetic member values from variables (defaults match the export, so it's a faithful copy)

Preconditions stop the plan if the export is missing, the snapshot is over 2 MB, or any inbound number would be bound. Check blocks warn if the export still references the source agent ID.

## Run it

```bash
# once: build and install the provider (from the repo root)
bash scripts/install-provider.sh
export BLAND_API_KEY="..."            # never commit it

cd scan
bash scripts/export.sh                # read-only; writes exports/agent_latest.json (git-ignored)
terraform init
terraform plan -out=scan.tfplan
terraform apply scan.tfplan
terraform output
```

## The demo change

```bash
terraform plan  -var 'release_note=v1.1 tighter benefits wording'   # shows: new version + new staging release
terraform apply -var 'release_note=v1.1 tighter benefits wording'
bash scripts/run-staging-checks.sh                                   # starts Bland's staging check run, prints per-judge verdicts
```

Promotion to production stays a human click in Environments, after the required judges pass.

## Tested

`test/run.sh` runs the full lifecycle against `test/mock_bland_v2.py` with no real API calls: apply, zero-diff plan, the `release_note` change, snapshot assertions, the check-run script, a different-member plan, and destroy. The mock also fails the test on any safety violation (promotion, inbound numbers, non-agent scenarios, unpublished judges in the gate, source KB leaking into the new snapshot).

```bash
bash test/run.sh
```

## Known limits

- **Judge rubric edits.** Publishing can mint a new draft, so each version config is pinned to the draft it was created with. To change a rubric, replace that judge: `terraform apply -replace='bland_eval_agent.judge["J1"]'`.
- **Judge field mapping.** Judges use the documented pass/fail shape (`prompt_md`, empty `levels`). Compare one against a dashboard-built judge in the UI after the first apply.
- **First production promotion** of a brand-new agent is a deliberate manual step.
- **The mock is not Bland.** It proves the Terraform and provider logic. Only a real apply proves the API contract.
