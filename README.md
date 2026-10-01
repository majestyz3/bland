# Bland Terraform Interview Demo

This repository is the runnable demo configuration for the companion provider:

- Provider: https://github.com/majestyz3/terraform-provider-bland
- Demo: this repository

It declaratively builds a synthetic **SCAN Member Services** experience for the Bland AI Solutions Engineering interview.

## What Terraform creates

- A Bland V2 Agent container named `SCAN Member Services - Terraform Demo`
- A text knowledge-base item containing synthetic member/benefit data
- A conversational pathway that demonstrates:
  - required disclosure with interruptions blocked
  - member ID + DOB authentication
  - benefits/member-service questions
  - replacement ID-card flow
  - simulated escalation
  - graceful end-call behavior

The demo intentionally does **not** buy phone numbers, place calls, send SMS, or transfer to a real person during `terraform apply`.

## Synthetic demo member

| Field | Value |
|---|---|
| Name | Maria Demo |
| Member ID | SCAN-DEMO-1001 |
| DOB | 01/15/1952 |
| Plan | SCAN Classic Demo Plan |
| PCP copay | $0 |
| Specialist copay | $15 |
| Replacement ID card | Eligible; simulated request completes in demo |

No real PHI or customer data is used.

## One-time setup

Requirements:

- Go 1.23+
- Terraform 1.6+
- Git
- A Bland API key

Clone both repositories next to each other:

```bash
git clone https://github.com/majestyz3/terraform-provider-bland.git
git clone https://github.com/majestyz3/bland.git

cd bland
bash scripts/install-provider.sh
```

Set your Bland key:

```bash
export BLAND_API_KEY="YOUR_KEY"
```

## Demo flow

Run:

```bash
bash scripts/preflight.sh
terraform init
terraform plan -out=demo.tfplan
terraform apply demo.tfplan
terraform plan
```

The final `terraform plan` should report no configuration changes.

Show the outputs:

```bash
terraform output
```

Then open the Bland dashboard and show the objects Terraform created.

## Reset

The resources in this repository are designed to be safe to recreate:

```bash
terraform destroy
```

The provider intentionally keeps one-shot operations such as placing calls, publishing/promoting versions, and running tests outside normal Terraform desired state.

## Interview walkthrough

See [DEMO_SCRIPT.md](./DEMO_SCRIPT.md) for the concise talk track and recovery plan.

## Provider maturity

The provider supports the modern V2 Agent lifecycle plus shared Bland configuration resources and read-only discovery data sources. The interview demo uses a deliberately small subset with well-documented public APIs so the live walkthrough stays deterministic.
