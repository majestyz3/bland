output "agent_id" {
  value = bland_agent.scan.id
}

output "dashboard" {
  value = {
    canvas       = "${local.dashboard_base}/configure/behavior"
    guardrails   = "${local.dashboard_base}/configure/guardrails"
    evaluations  = "${local.dashboard_base}/judges"
    environments = "${local.dashboard_base}/environments"
  }
}

output "version_id" {
  value = bland_agent_version.candidate.id
}

output "staging_version_number" {
  value = bland_agent_release.staging.version_number
}

output "knowledge_base_id" {
  value = bland_knowledge_base.benefits.id
}

output "judges" {
  value = { for k, j in bland_eval_agent_publish.judge : k => j.active_version_id }
}

output "test_scenarios" {
  value = { for k, t in bland_agent_test_scenario.test : k => t.id }
}

output "snapshot_bytes" {
  value = local.snapshot_bytes
}
