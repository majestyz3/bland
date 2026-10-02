# A brand-new V2 agent. The dashboard-built agent is never referenced here.
resource "bland_agent" "scan" {
  name = var.agent_name
}

# Immutable version built from the exported snapshot. Changing release_note
# (the version name) or the snapshot creates a new version.
resource "bland_agent_version" "candidate" {
  agent_id      = bland_agent.scan.id
  name          = var.release_note
  snapshot_json = local.snapshot_text

  lifecycle {
    precondition {
      condition     = local.snapshot_text != null
      error_message = "No source snapshot found at ${var.source_snapshot_path}. Run scripts/export.sh with BLAND_API_KEY set first."
    }
    precondition {
      condition     = local.snapshot_bytes < 2000000
      error_message = "Rendered snapshot exceeds Bland's 2 MB limit."
    }
    precondition {
      condition     = length(try(local.snapshot_object.contact.inboundNumbers, [])) == 0
      error_message = "The new agent must not bind any inbound phone numbers."
    }
  }
}
