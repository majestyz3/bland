# Interview Demo Script

## 90-second setup story

“I built the Bland experience first to learn the platform. Then I noticed the existing Terraform provider was based on an older API surface, so I wrote a new provider from scratch against Bland's current public APIs. This repo is the consumer side: it reproduces the SCAN member-services demo declaratively.”

Show the two repos:
- `terraform-provider-bland` — provider implementation
- `bland` — actual Terraform configuration using it

## Live sequence

1. Run `./scripts/preflight.sh`.
2. Run `terraform plan`.
3. Point out the resources:
   - V2 agent container
   - synthetic knowledge-base item
   - conversational pathway
4. Run `terraform apply`.
5. Run `terraform output` and show the generated IDs.
6. Open Bland and show the matching objects.
7. Run `terraform plan` again and highlight the clean/no-change result.

## What to say about the flow

The pathway demonstrates:

1. **Required disclosure** — per-node interruptibility is set to `0`, so the disclosure finishes before interruption.
2. **Authentication** — extracts member ID and DOB and requires both synthetic values.
3. **Grounded member servicing** — benefits are constrained to fictional SCAN demo data.
4. **Replacement ID card** — simulates submission without pretending a real fulfillment system was called.
5. **Escalation** — intentionally simulated; no real person or transfer destination is configured.
6. **End call** — closes cleanly.

Synthetic credentials:

- Maria Demo
- `SCAN-DEMO-1001`
- `01/15/1952`

## Architecture answer

“Terraform owns durable configuration. I deliberately did not model calls, SMS sends, publishing, test executions, or other one-shot actions as ordinary resources because a repeat `terraform apply` should never accidentally trigger real-world activity.”

## If live API creation misbehaves

Do not debug blindly in front of the interviewer.

1. Show the Terraform plan and provider code.
2. Show GitHub Actions passing for the provider.
3. Show the Bland objects from the previously successful rehearsal.
4. Explain that the provider uses only documented public endpoints and that the failing operation is isolated by resource.
5. Continue with the architecture discussion.

## Cleanup

After rehearsal—not immediately before the interview unless you intend to recreate everything:

```bash
terraform destroy
```
