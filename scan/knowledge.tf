# Text knowledge base for the new agent. The provider waits for COMPLETED
# before anything that depends on the ID continues.
resource "bland_knowledge_base" "benefits" {
  config_json = jsonencode({
    type        = "text"
    name        = "SCAN Demo Member Benefits KB (Terraform)"
    description = "DEMO DATA ONLY. Synthetic benefits, ID card, pharmacy, enrollment, and fallback rules for the SCAN demo."
    text        = file("${path.module}/content/kb_scan_demo_member_benefits.txt")
  })
  ready_timeout = "5m"
}
