# Tomorrow Rehearsal Checklist

Use this checklist once tonight and once before the interview.

## 1. Update both repos

```bash
cd terraform-provider-bland
git pull

cd ../bland
git pull
```

## 2. Install the provider build used by the demo

From the `bland` repository:

```bash
bash scripts/install-provider.sh
```

Expected result: provider tests, `go vet`, and build all pass and the local `v0.1.0` binary is installed under `~/.terraform.d/plugins`.

## 3. Set your API key

```bash
export BLAND_API_KEY="YOUR_REAL_BLAND_API_KEY"
```

Do not put the key in Terraform files, shell history screenshots, Git commits, or interview screen shares.

## 4. Run preflight

```bash
bash scripts/preflight.sh
```

This verifies Terraform, Git, the API-key environment variable, formatting, provider discovery, init, and validation.

## 5. Run the real Bland rehearsal

```bash
terraform plan -out=demo.tfplan
terraform apply demo.tfplan
terraform output
terraform plan
```

Success criteria:

- Agent is visible in Bland.
- Knowledge-base item is visible in Bland.
- Pathway is visible in Bland with all six stages.
- The second `terraform plan` reports no changes.

## 6. Inspect the pathway in Bland

Confirm these nodes exist:

1. Required Disclosure
2. Authenticate Demo Member
3. Member Benefits and Services
4. Replacement ID Card
5. Simulated Escalation
6. End Call

Confirm the disclosure node has interruptions blocked.

## 7. Rehearse the conversation

Use only the synthetic member:

- **Name:** Maria Demo
- **Member ID:** `SCAN-DEMO-1001`
- **DOB:** `01/15/1952`

Suggested flow:

1. Let the disclosure finish.
2. Give the demo member ID and DOB.
3. Ask: “What is my specialist copay?”
4. Ask: “Can you send me a replacement ID card?”
5. Ask: “Can I speak with a person?”
6. Finish the interaction.

Expected demo answers:

- Specialist copay: **$15**
- Replacement card: **simulated successful submission**
- Human handoff: **simulated escalation; no real transfer destination**

## 8. Before the interview

Do **not** destroy the successfully rehearsed environment.

Run only:

```bash
terraform plan
terraform output
```

If the plan is clean, leave the environment exactly as-is.

Keep two browser tabs ready:

1. GitHub: `terraform-provider-bland`
2. Bland dashboard: the SCAN demo pathway/agent

Keep one terminal in the `bland` repository.

## 9. During the interview

Recommended sequence:

```bash
terraform plan
terraform output
```

Show the clean plan first. You do not need to destroy and recreate the entire demo live unless the interviewer specifically wants to see creation.

If you want to demonstrate a change, make a harmless text change to the pathway description, run `terraform plan`, show the diff, apply it, then show the updated object in Bland.

## 10. Recovery plan

If Bland itself is unavailable or rate-limited:

- Show the passing GitHub Actions run in this repository.
- Explain that CI performs the complete Terraform lifecycle against a deterministic mock Bland API.
- Show the provider's own passing build/test/vet workflow.
- Continue with the architecture and code walkthrough.

The CI lifecycle is:

```text
provider build
→ local provider install
→ terraform init
→ terraform validate
→ terraform apply
→ zero-diff terraform plan
→ terraform destroy
```

That gives you a deterministic fallback even if the live SaaS has an issue during the interview.
