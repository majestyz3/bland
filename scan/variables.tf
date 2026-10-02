variable "agent_name" {
  description = "Display name of the new agent Terraform creates."
  type        = string
  default     = "SCAN Member Services (Terraform)"
}

variable "source_snapshot_path" {
  description = "Exported snapshot of the dashboard-built agent (written by scripts/export.sh)."
  type        = string
  default     = "exports/agent_latest.json"
}

variable "source_agent_id" {
  description = "Dashboard-built agent the snapshot was exported from. Read only; never modified."
  type        = string
  default     = "c6cf39fb-724c-463c-ba02-2a08f86b324d"
}

variable "release_note" {
  description = "Name of the agent version. Changing it creates a new immutable version and a new staging release, which triggers Bland's staging checks. This is the demo change."
  type        = string
  default     = "v1 baseline"
}

variable "release_bump" {
  description = "Semver component to bump when a version is first published: patch, minor, or major."
  type        = string
  default     = "minor"

  validation {
    condition     = contains(["patch", "minor", "major"], var.release_bump)
    error_message = "release_bump must be patch, minor, or major."
  }
}

variable "enable_promotion" {
  description = "Promote staging to production after release. Off by default: production stays a human decision."
  type        = bool
  default     = false
}

variable "create_alarm" {
  description = "Create an org-level API error alarm. The public alarm API is org-wide, not per agent."
  type        = bool
  default     = false
}

variable "alarm_threshold" {
  description = "Threshold value passed to the alarm API for metric_type api_errors."
  type        = number
  default     = 1
}

# Synthetic test member. Defaults match the exported snapshot, so changing them
# rewrites the identity answers, tool code, and test prompts consistently.
variable "member_id" {
  description = "Synthetic member ID."
  type        = string
  default     = "SCAN-DEMO-1001"
}

variable "member_first_name" {
  type    = string
  default = "Majid"
}

variable "member_last_name" {
  type    = string
  default = "Zarkesh"
}

variable "member_dob" {
  description = "Synthetic date of birth, ISO format (YYYY-MM-DD)."
  type        = string
  default     = "1994-10-30"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.member_dob))
    error_message = "member_dob must be YYYY-MM-DD."
  }
}

variable "escalation_number" {
  description = "Transfer destination for failed verification. Default is a fictional 555-01xx number that cannot reach anyone."
  type        = string
  default     = "+12025550100"
}
