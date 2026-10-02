# Plan-time warnings (Terraform check blocks warn, they don't fail).
check "source_agent_not_embedded" {
  assert {
    condition     = local.source_agent_refs == 0
    error_message = "The exported snapshot references the source agent ID ${var.source_agent_id} ${local.source_agent_refs} time(s). Review before applying."
  }
}

check "single_source_kb" {
  assert {
    condition     = length(local.source_kb_ids) <= 1
    error_message = "The source snapshot attaches more than one knowledge base; only the first is remapped."
  }
}
