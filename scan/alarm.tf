# Optional org-level API error alarm. The public alarm API has no per-agent
# scoping, so the per-agent alert stays in the dashboard.
resource "bland_alarm" "api_errors" {
  count = var.create_alarm ? 1 : 0

  config_json = jsonencode({
    metric_type = "api_errors"
    threshold   = var.alarm_threshold
  })
}
