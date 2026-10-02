# Rehearsal checklist (tonight)

1. **Update and build**
   ```bash
   cd terraform-provider-bland && git pull && cd ../bland && git pull
   bash scripts/install-provider.sh
   ```
2. **Offline test, no key needed:** `bash scan/test/run.sh` should end with `ALL SCAN TESTS PASSED`.
3. **Export the dashboard agent:** `export BLAND_API_KEY=...`, then `cd scan && bash scripts/export.sh`. Skim `exports/agent_latest.json`.
4. **Plan, then apply:** `terraform init && terraform plan -out=scan.tfplan && terraform apply scan.tfplan`.
5. **Zero-diff check:** `terraform plan` should say no changes.
6. **Behavior check in the dashboard:** open the new agent, run its Test A from Evaluations. Expect the disclosure, three verification questions, "fifteen dollars", and `DEMO-ID-4821`.
7. **Judges:** open one TF judge next to its dashboard twin and compare the rubric.
8. **Rehearse the change:** `release_note` plan, apply, then `bash scripts/run-staging-checks.sh`.
9. **Stop rule:** if steps 3 to 6 fight you for more than an hour, stop. Present Terraform from the code and the offline test instead.
