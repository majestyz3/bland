# Five LLM judges (J1 to J5). Pass/fail mode: levels and target_level_keys are
# empty, per the Eval Agent Version API docs. Rubric text is verbatim from
# content/judges.json.
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
    system_prompt_md  = local.judge_system_prompt
    prompt_md         = "${each.value.task}\n\n**Pass** if: ${each.value.pass}\n\n**Fail** if: ${each.value.fail}"
    levels            = []
    target_level_keys = []
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
