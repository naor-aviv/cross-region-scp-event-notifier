resource "aws_cloudformation_stack_set" "eventbridge_rule" {
  name             = "${var.project_name}-eventbridge-rule"
  description      = "CloudFormation StackSet that deploys the relevant EventBridge rule in each account"
  template_body    = file("./files/eventbridge_rule_cf_template.yaml")
  permission_model = "SERVICE_MANAGED"

  capabilities = ["CAPABILITY_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  parameters = {
    EventBusDestinationAccount = data.aws_caller_identity.current.account_id
    EventBusDestinationRegion  = var.aws_region
    EventBusName               = "CrossAccountDestinationBus"
  }

  operation_preferences {
    failure_tolerance_percentage = 100
    max_concurrent_percentage    = 100
    region_concurrency_type      = "PARALLEL"
  }

  lifecycle {
    ignore_changes = [
      # Ignoring the change of "administration_role_arn" as StackSet with auto_deployment gets administration_role_arn during refresh, resulting in update loop
      # https://github.com/hashicorp/terraform-provider-aws/issues/23464
      administration_role_arn
    ]
  }

  depends_on = [aws_cloudwatch_event_bus.cross_account]
}

resource "aws_cloudformation_stack_set_instance" "eventbridge_rule" {
  stack_set_name = aws_cloudformation_stack_set.eventbridge_rule.name
  region         = var.aws_region

  deployment_targets {
    organizational_unit_ids = var.deploy_to_organization ? [data.aws_organizations_organization.current.roots[0].id] : var.include_organizational_units
  }

  operation_preferences {
    failure_tolerance_percentage = 100
    max_concurrent_percentage    = 100
    region_concurrency_type      = "PARALLEL"
  }
}