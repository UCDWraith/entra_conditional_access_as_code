variable "access_token" {
  description = "Access token for authenticating with the Graph API. This Azure DevOps implementation retrieved and populated the token in the CI pipeline."
  type        = string
  sensitive   = true
}

locals {
  ca_policy_files = [
    "iac_cap_001.json",
    "iac_cap_002.json",
    "iac_cap_003.json",
    "iac_cap_004.json",
    "iac_cap_005.json",
    "iac_cap_006.json",
    "iac_cap_007.json",
    "iac_cap_008.json",
    "iac_cap_011.json",
    "iac_cap_012.json",
    "iac_cap_013.json"
    // Add more policy files as needed
  ]

  exception_policy_files = [
    "iac_cap_009.json",
    "iac_cap_010.json"
    // Add more exception policy files as needed
  ]

  # previous_policy_files_set = fileexists("${path.module}/previous_policies.txt") ? toset(split("\n", trimspace(file("${path.module}/previous_policies.txt")))) : toset([])
}

# Data source for Terraform native policy files
data "local_file" "ca_policies" {
  for_each = toset(local.ca_policy_files)
  filename = "${path.module}/lib/${each.value}"
}

# Data source for exception policy files
data "local_file" "exception_ca_policies" {
  for_each = toset(local.exception_policy_files)
  filename = "${path.module}/exceptions/${each.value}"
}

# Track previously managed policies
# resource "local_file" "previous_policies" {
#   filename = "${path.module}/previous_policies.txt"
#   content  = join("\n", local.exception_policy_files)
# }

# Resource for creating conditional access policies via native Terraform commands
resource "azuread_conditional_access_policy" "ca_policy" {
  for_each = data.local_file.ca_policies

  display_name = jsondecode(each.value.content).displayName
  state        = jsondecode(each.value.content).state
  conditions {
    applications {
      included_applications = try(jsondecode(each.value.content).conditions.applications.includeApplications, null)
      excluded_applications = try(jsondecode(each.value.content).conditions.applications.excludeApplications, null)
      included_user_actions = try(jsondecode(each.value.content).conditions.applications.includeUserActions, null)
    }

    client_app_types = jsondecode(each.value.content).conditions.clientAppTypes

    dynamic "client_applications" {
      for_each = try(jsondecode(each.value.content).conditions.clientApplications, null) != null ? [1] : []

      content {
        excluded_service_principals = try(jsondecode(each.value.content).conditions.clientApplications.excludeServicePrincipals, [])
        included_service_principals = try(jsondecode(each.value.content).conditions.clientApplications.includeServicePrincipals, [])
      }
    }

    dynamic "devices" {
      for_each = try(jsondecode(each.value.content).conditions.devices, null) != null ? [1] : []

      content {
        dynamic "filter" {
          for_each = try(jsondecode(each.value.content).conditions.devices.deviceFilter, null) != null ? [1] : []

          content {
            mode = jsondecode(each.value.content).conditions.devices.deviceFilter.mode
            rule = jsondecode(each.value.content).conditions.devices.deviceFilter.rule
          }
        }
      }
    }

    dynamic "locations" {
      for_each = try(jsondecode(each.value.content).conditions.locations, null) != null ? [1] : []

      content {
        included_locations = jsondecode(each.value.content).conditions.locations.includeLocations
        excluded_locations = jsondecode(each.value.content).conditions.locations.excludeLocations
      }
    }

    dynamic "platforms" {
      for_each = try(jsondecode(each.value.content).conditions.platforms, null) != null ? [1] : []

      content {
        included_platforms = jsondecode(each.value.content).conditions.platforms.includePlatforms
        excluded_platforms = try(jsondecode(each.value.content).conditions.platforms.excludePlatforms, [])
      }
    }

    service_principal_risk_levels = try(jsondecode(each.value.content).conditions.servicePrincipalRiskLevels, [])

    sign_in_risk_levels = try(jsondecode(each.value.content).conditions.signInRiskLevels, [])

    user_risk_levels = try(jsondecode(each.value.content).conditions.userRiskLevels, [])

    users {
      excluded_groups = try(jsondecode(each.value.content).conditions.users.excludeGroups, [])
      excluded_roles  = try(jsondecode(each.value.content).conditions.users.excludeRoles, [])
      excluded_users  = try(jsondecode(each.value.content).conditions.users.excludeUsers, [])
      #   excluded_guests_or_external_users {
      #     external_tenants {
      #       members = []
      #       membership_kind = 
      #     }
      #     guest_or_external_user_types = 
      #   }
      included_users  = try(jsondecode(each.value.content).conditions.users.includeUsers, [])
      included_groups = try(jsondecode(each.value.content).conditions.users.includeGroups, [])
      included_roles  = try(jsondecode(each.value.content).conditions.users.includeRoles, [])
      #   included_guests_or_external_users {
      #     external_tenants {
      #       members = []
      #       membership_kind = 
      #     }
      #     guest_or_external_user_types = 
      #   }
    }
  }

  dynamic "grant_controls" {
    for_each = try(jsondecode(each.value.content).grantControls, null) != null ? [1] : []
    content {
      authentication_strength_policy_id = try(jsondecode(each.value.content).grantControls.authenticationStrength.id, null)
      built_in_controls                 = try(jsondecode(each.value.content).grantControls.builtInControls, [])
      custom_authentication_factors     = try(jsondecode(each.value.content).grantControls.customAuthenticationFactors, [])
      operator                          = jsondecode(each.value.content).grantControls.operator
      terms_of_use                      = try(jsondecode(each.value.content).grantControls.termsOfUse, [])
    }
  }

  dynamic "session_controls" {
    for_each = try(jsondecode(each.value.content).sessionControls, null) != null ? [1] : []
    content {
      application_enforced_restrictions_enabled = try(jsondecode(each.value.content).sessionControls.applicationEnforcedRestrictions, false)
      cloud_app_security_policy                 = try(jsondecode(each.value.content).sessionControls.cloudAppSecurity, null)
      disable_resilience_defaults               = try(jsondecode(each.value.content).sessionControls.disableResilienceDefaults, false)
      persistent_browser_mode                   = try(jsondecode(each.value.content).sessionControls.persistentBrowser.mode, null)
      sign_in_frequency                         = try(jsondecode(each.value.content).sessionControls.signInFrequency.value, null)
      sign_in_frequency_authentication_type     = try(jsondecode(each.value.content).sessionControls.signInFrequency.authenticationType, "primaryAndSecondaryAuthentication")
      sign_in_frequency_interval                = try(jsondecode(each.value.content).sessionControls.signInFrequency.frequencyInterval, "timeBased")
      sign_in_frequency_period                  = try(jsondecode(each.value.content).sessionControls.signInFrequency.type, null)
    }
  }
}

# Resource for creating conditional access policies from exception files
resource "null_resource" "create_exception_ca_policy" {
  count = length(local.exception_policy_files)

  provisioner "local-exec" {
    command = <<EOT
    curl -X POST https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies \
      -H "Authorization: Bearer ${var.access_token}" \
      -H "Content-Type: application/json" \
      -d @${path.module}/exceptions/${local.exception_policy_files[count.index]}
    EOT
  }

  triggers = {
    policy_file = "${path.module}/exceptions/${local.exception_policy_files[count.index]}"
  }
}

# resource "null_resource" "destroy_removed_policies" {
#   count = length(local.previous_policy_files_set) == 0 ? 0 : 1

#   provisioner "local-exec" {
#     command = <<EOT
#     #!/bin/bash

#     old_policies=$(cat ${path.module}/previous_policies.txt)
#     current_policies=$(echo ${join(" ", local.exception_policy_files)})

#     for policy in $old_policies; do
#       if ! echo "$current_policies" | grep -qw "$policy"; then
#         echo "Deleting policy: $policy"
#         curl -X DELETE https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies/$policy \
#           -H "Authorization: Bearer ${var.access_token}" \
#           -H "Content-Type: application/json"
#       fi
#     done
#     EOT
#   }

#   depends_on = [local_file.previous_policies]
# }

output "create_exception_ca_policy_status" {
  value = null_resource.create_exception_ca_policy[*].id
}