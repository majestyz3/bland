#!/usr/bin/env bash
# Full lifecycle test of scan/ against the V2 mock API. No real Bland calls.
set -euo pipefail
cd "$(dirname "$0")/.."
PORT=18081
export BLAND_API_KEY=mock-test-key BLAND_BASE_URL="http://127.0.0.1:$PORT"
export TF_VAR_source_snapshot_path="test/fixtures/agent_latest.json"
STATE="-state=test/terraform.tfstate"
python3 test/mock_bland_v2.py $PORT 2>test/mock.log & MOCK=$!
trap 'kill $MOCK 2>/dev/null; rm -f test/terraform.tfstate*' EXIT
sleep 1

step() { echo; echo "== $*"; }
violations() { curl -s "$BLAND_BASE_URL/__violations" | python3 -c 'import json,sys; v=json.load(sys.stdin)["data"]; print("violations:", v or "none"); sys.exit(1 if v else 0)'; }

step "1. apply (create everything)";      terraform apply -auto-approve -no-color $STATE >test/apply1.log && tail -1 test/apply1.log
step "2. idempotency (expect no changes)"; set +e; terraform plan -detailed-exitcode -no-color $STATE >test/plan1.log; rc=$?; set -e
echo "plan exit: $rc"; [ $rc -eq 0 ] || { grep -E "must be replaced|will be updated|will be created|~|forces" test/plan1.log | head -20; exit 1; }
step "3. demo change: release_note";       terraform plan -no-color $STATE -var 'release_note=v1.1 tighter benefits wording' | grep -E "Plan:|bland_agent_version|bland_agent_release" | head -6
terraform apply -auto-approve -no-color $STATE -var 'release_note=v1.1 tighter benefits wording' >test/apply2.log && tail -1 test/apply2.log
step "4. snapshot transformation checks"
python3 - <<'PY'
import json
st=json.load(open('test/terraform.tfstate'))
res={r['type']+'.'+r['name']:r for r in st['resources']}
snap=json.loads(res['bland_agent_version.candidate']['instances'][0]['attributes']['snapshot_json'])
kb=res['bland_knowledge_base.benefits']['instances'][0]['attributes']['id']
t=json.dumps(snap)
checks={
 'new KB attached': snap['knowledge']['kbIds']==[kb],
 'source KB removed': 'kb_source_fixture_0001' not in t,
 'display name set': snap['settings']['displayName']=='SCAN Member Services (Terraform)',
 'no inbound numbers': snap['contact']['inboundNumbers']==[],
 'member values intact': all(s in t for s in ['SCAN-DEMO-1001','10/30/1994 (October 30, 1994)','Majid Zarkesh','DEMO1001','10301994',"'Majid'"]),
 'fictional transfer number': '+12025550100' in t,
 'version renamed': res['bland_agent_version.candidate']['instances'][0]['attributes']['name'].startswith('v1.1'),
 '6 test cases': len(res['bland_agent_test_scenario.test']['instances'])==6,
 '5 judges published': len(res['bland_eval_agent_publish.judge']['instances'])==5,
 'no promotion': 'bland_agent_promotion.production' not in res or not res['bland_agent_promotion.production']['instances'],
}
for k,v in checks.items(): print(('PASS ' if v else 'FAIL ')+k)
gate=json.loads(res['bland_agent_checks.staging']['instances'][0]['attributes']['config_json'])
print('gate: %d scenarios, required=%s' % (len(gate['scenario_ids']), [e['required'] for e in gate['evals']]))
assert all(checks.values())
PY
violations
step "4b. staging check script (mock)"
POLL_SECONDS=1 terraform output -state=test/terraform.tfstate -raw agent_id >/dev/null
POLL_SECONDS=1 bash scripts/run-staging-checks.sh "$(terraform output -state=test/terraform.tfstate -raw agent_id)" "$(terraform output -state=test/terraform.tfstate -raw version_id)"
violations
step "5. variable override (different member)"
terraform plan -no-color $STATE -var member_id=SCAN-DEMO-2002 -var member_dob=1950-03-07 -var member_first_name=Ana -var member_last_name=Test >test/plan3.log
grep -E "Plan:" test/plan3.log
step "6. destroy";                         terraform destroy -auto-approve -no-color $STATE >test/destroy.log && tail -1 test/destroy.log
violations
echo; echo "ALL SCAN TESTS PASSED"
