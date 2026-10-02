# Staging release gate: Tests A to E, J1 to J4 required, J5 advisory,
# one simulated conversation per test case.
resource "bland_agent_checks" "staging" {
  agent_id    = bland_agent.scan.id
  environment = "staging"

  config_json = jsonencode({
    scenario_ids = [for k, s in local.scenarios : bland_agent_test_scenario.test[k].id if s.gated]
    evals = [for k, j in local.judges : {
      eval_agent_id         = bland_eval_agent.judge[k].id
      eval_agent_version_id = bland_eval_agent_publish.judge[k].active_version_id
      target_level_keys     = ["meets_criteria"]
      required              = j.required
    }]
    enabled           = true
    simulations_count = 1
  })
}
