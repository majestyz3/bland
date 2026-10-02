# Publish the candidate version to staging. Bland runs the staging checks.
resource "bland_agent_release" "staging" {
  agent_id   = bland_agent.scan.id
  version_id = bland_agent_version.candidate.id
  bump       = var.release_bump

  depends_on = [bland_agent_checks.staging]
}

# Production promotion is opt-in. Leave it off for the demo: a human promotes
# in Environments once the required judges pass.
resource "bland_agent_promotion" "production" {
  count = var.enable_promotion ? 1 : 0

  agent_id = bland_agent.scan.id
  triggers = {
    version = bland_agent_release.staging.version_number
  }
}
