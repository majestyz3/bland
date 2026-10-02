# Six simulated-caller test cases on the new agent.
resource "bland_agent_test_scenario" "test" {
  for_each = local.scenarios

  agent_id   = bland_agent.scan.id
  name       = each.value.name
  prompt     = trimspace(each.value.prompt)
  max_turns  = 20
  extra_json = local.scenario_extra
}
