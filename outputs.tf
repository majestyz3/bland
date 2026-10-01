output "agent_id" {
  description = "Bland V2 Agent ID created by Terraform."
  value       = bland_agent.scan_member_services.id
}

output "pathway_id" {
  description = "Bland conversational pathway ID used for the member-services demo."
  value       = bland_conversational_pathway.scan_member_services.id
}

output "knowledge_base_id" {
  description = "Synthetic SCAN demo knowledge-base item ID."
  value       = bland_knowledge_base.scan_member_services.id
}

output "demo_member" {
  description = "Synthetic credentials to use during the interview demo."
  value = {
    name      = "Maria Demo"
    member_id = "SCAN-DEMO-1001"
    dob       = "01/15/1952"
  }
}
