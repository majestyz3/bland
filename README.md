# Bland Terraform demo

Terraform configurations for the SCAN Member Services interview demo, using the companion provider [terraform-provider-bland](https://github.com/majestyz3/terraform-provider-bland).

| Path | What it is |
|---|---|
| [`scan/`](./scan) | **Main demo.** A brand-new Bland V2 agent with the full SCAN build: deterministic disclosure, three-factor auth zone, gated member services and ID card pathways, escalation, guardrails, knowledge base, five judges, six test cases, a staging release gate, and a staging release. |
| repo root (`main.tf`) | Small legacy example: a V2 agent container, a knowledge base, and a V1 conversational pathway. Kept because CI exercises it and it shows the older API surface. |

No real PHI. The synthetic test member is `SCAN-DEMO-1001`, DOB `10/30/1994`, Majid Zarkesh (the demo builder). Nothing creates phone numbers, places calls, sends SMS, or transfers to a real person.

## Setup

```bash
git clone https://github.com/majestyz3/terraform-provider-bland.git
git clone https://github.com/majestyz3/bland.git
cd bland
bash scripts/install-provider.sh     # provider tests, vet, build, local install
export BLAND_API_KEY="..."
```

Then follow [`scan/README.md`](./scan/README.md).

## CI

GitHub Actions builds the provider from source and runs two jobs with no real Bland key:

- **root:** fmt, init, validate, apply, zero-diff plan, destroy against `scripts/mock_bland.py`
- **scan:** fmt, init, validate, then `scan/test/run.sh` against `scan/test/mock_bland_v2.py` (apply, zero-diff plan, release change, snapshot and safety assertions, check-run script, destroy)

See [DEMO_SCRIPT.md](./DEMO_SCRIPT.md) for the talk track and [REHEARSAL_CHECKLIST.md](./REHEARSAL_CHECKLIST.md) for tonight.
