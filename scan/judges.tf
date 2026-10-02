# Five LLM judges (J1 to J5), mirroring how the dashboard stores them:
# Pass and Fail as levels, with meets_criteria as the passing level.
# The system prompt is Bland's own default, read from the exported judges.
locals {
  judge_version_files = tolist(fileset("${path.module}/exports/judges", "version_*.json"))
  bland_judge_system_prompt = try(
    jsondecode(file("${path.module}/exports/judges/${local.judge_version_files[0]}")).data.system_prompt_md,
    local.judge_system_prompt
  )
}

resource "bland_eval_agent" "judge" {
  for_each = local.judges

  config_json = jsonencode({
    name        = "${each.value.name} (TF)"
    description = each.value.description
    modality    = "text"
  })
}

resource "bland_eval_agent_version_config" "judge" {
  for_each = local.judges

  parent_id  = bland_eval_agent.judge[each.key].id
  version_id = bland_eval_agent.judge[each.key].current_version_id
  config_json = jsonencode({
    system_prompt_md = local.bland_judge_system_prompt
    prompt_md        = each.value.task
    levels = [
      { level_key = "does_not_meet_criteria", label = "Fail", color = "rose", prompt_md = each.value.fail },
      { level_key = "meets_criteria", label = "Pass", color = "emerald", prompt_md = each.value.pass },
    ]
    target_level_keys = ["meets_criteria"]
  })

  # Publishing can mint a new draft, which changes the eval agent's
  # current_version_id. Pin to the draft that existed at creation so later
  # plans stay clean. To change a rubric: terraform apply -replace='bland_eval_agent.judge["J1"]'
  lifecycle {
    ignore_changes = [version_id]
  }
}

resource "bland_eval_agent_publish" "judge" {
  for_each = local.judges

  eval_agent_id = bland_eval_agent.judge[each.key].id

  # Republish only when the rubric text changes, not when the draft ID moves.
  triggers = {
    config = sha256(bland_eval_agent_version_config.judge[each.key].config_json)
  }

  depends_on = [bland_eval_agent_version_config.judge]
}
