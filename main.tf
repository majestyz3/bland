terraform {
  required_version = ">= 1.6.0"

  required_providers {
    bland = {
      source  = "majestyz3/bland"
      version = "0.1.0"
    }
  }
}

provider "bland" {}

locals {
  demo_member_knowledge = <<-EOT
    SCAN MEMBER SERVICES DEMO DATA — SYNTHETIC ONLY

    Member:
    - Name: Maria Demo
    - Member ID: SCAN-DEMO-1001
    - Date of birth: 01/15/1952
    - Plan: SCAN Classic Demo Plan
    - Coverage status: Active

    Benefits:
    - Primary care physician visit copay: $0
    - Specialist visit copay: $15
    - Preventive care: $0 copay for covered preventive services
    - Urgent care: $25 copay
    - Emergency room: $90 copay, waived if admitted
    - Generic prescription: $5 demo copay

    ID cards:
    - Maria Demo is eligible for a replacement member ID card.
    - In this demonstration, a replacement request is simulated and should be described as submitted successfully.
    - Do not claim a real physical card was ordered or shipped.

    Escalation:
    - If the caller asks for a human, has a complaint, reports an emergency, or needs help outside the synthetic demo data, explain that this is a demonstration and simulate escalation.
    - Never invent benefits, coverage, claims, providers, authorizations, or medical advice.

    Privacy:
    - All data in this demo is fictional.
    - The agent must authenticate using BOTH member ID SCAN-DEMO-1001 and DOB 01/15/1952 before discussing member-specific information.
  EOT

  pathway_nodes = [
    {
      id   = "disclosure"
      type = "Default"
      data = {
        name    = "Required Disclosure"
        isStart = true
        text    = "Thank you for calling the SCAN Member Services demonstration. This is an AI-powered demo using fictional member information and does not access real health records. Before we continue, I need to verify the demo member."
        modelOptions = {
          interruptibility = 0
        }
      }
    },
    {
      id   = "authenticate"
      type = "Default"
      data = {
        name   = "Authenticate Demo Member"
        prompt = "Ask for the caller's member ID and date of birth. Extract both values. Do not reveal any member-specific information until both match the synthetic demo member. The valid values are member ID SCAN-DEMO-1001 and DOB 01/15/1952. If either value does not match, politely explain that authentication failed and do not disclose benefits."
        extractVars = [
          ["member_id", "string", "Member ID provided by the caller"],
          ["date_of_birth", "string", "Date of birth provided by the caller in MM/DD/YYYY format"]
        ]
      }
    },
    {
      id   = "member_services"
      type = "Knowledge Base"
      data = {
        name   = "Member Benefits and Services"
        prompt = "The caller is authenticated. Answer questions only from the synthetic SCAN demo knowledge below. Be concise and conversational. If information is not present, say you do not have it in this demonstration and offer simulated escalation."
        kb     = local.demo_member_knowledge
      }
    },
    {
      id   = "replace_id"
      type = "Default"
      data = {
        name   = "Replacement ID Card"
        prompt = "If the authenticated caller asks for a replacement ID card, confirm the request and explain that this demo simulates a successful replacement-card submission. Do not claim a real card was ordered, mailed, or shipped."
      }
    },
    {
      id   = "escalation"
      type = "Default"
      data = {
        name   = "Simulated Escalation"
        prompt = "Explain that in production this point could transfer to a human member-services representative, but this interview environment intentionally performs a simulated escalation and does not call a real transfer destination."
      }
    },
    {
      id   = "end_call"
      type = "End Call"
      data = {
        name   = "End Call"
        prompt = "Summarize what was handled in one sentence, ask whether there is anything else within the demo scope, then thank the caller and end the call."
      }
    }
  ]

  pathway_edges = [
    {
      id     = "e1"
      source = "disclosure"
      target = "authenticate"
      data = {
        label = "After the required disclosure has been fully spoken"
      }
    },
    {
      id     = "e2"
      source = "authenticate"
      target = "member_services"
      data = {
        label = "Both member_id equals SCAN-DEMO-1001 and date_of_birth equals 01/15/1952"
      }
    },
    {
      id     = "e3"
      source = "authenticate"
      target = "end_call"
      data = {
        label = "Authentication fails or caller will not provide both demo credentials"
      }
    },
    {
      id     = "e4"
      source = "member_services"
      target = "replace_id"
      data = {
        label = "Caller asks to replace or resend their member ID card"
      }
    },
    {
      id     = "e5"
      source = "member_services"
      target = "escalation"
      data = {
        label = "Caller requests a human, complains, or asks for information outside the demo knowledge"
      }
    },
    {
      id     = "e6"
      source = "member_services"
      target = "end_call"
      data = {
        label = "Caller has no additional member-service questions"
      }
    },
    {
      id     = "e7"
      source = "replace_id"
      target = "member_services"
      data = {
        label = "Replacement-card demo step is complete and caller has another question"
      }
    },
    {
      id     = "e8"
      source = "replace_id"
      target = "end_call"
      data = {
        label = "Replacement-card demo step is complete and caller is finished"
      }
    },
    {
      id     = "e9"
      source = "escalation"
      target = "end_call"
      data = {
        label = "Simulated escalation has been explained"
      }
    }
  ]
}

resource "bland_agent" "scan_member_services" {
  name = "SCAN Member Services - Terraform Demo"
}

resource "bland_knowledge_base" "scan_member_services" {
  config_json = jsonencode({
    type        = "text"
    name        = "SCAN Member Services Demo Knowledge"
    description = "Synthetic member benefits and servicing information for the Terraform interview demo."
    text        = local.demo_member_knowledge
  })
}

resource "bland_conversational_pathway" "scan_member_services" {
  config_json = jsonencode({
    name        = "SCAN Member Services - Terraform Demo"
    description = "Synthetic member-services flow: disclosure, authentication, benefits, replacement ID card, escalation, and end call."
    nodes       = local.pathway_nodes
    edges       = local.pathway_edges
  })
}
