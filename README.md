# AWS Organizational Events Notifier

The AWS Organizational Events Notifier tool will notify a set of recipients for a specific set of events triggered in any account in the organization.

For example, it can notify send an email to the FinOps engineer whenever someone tries to redeem AWS Credits in any of the linked accounts in the organization.

Although the tool is being deployed with Terraform, the Terraform module will also deploy a set of resources with CloudFormation StackSets as there is a limitation with Terraform ("dynamic providers")

The following resources are being created as part of this module:
- Organizational CloudTrail Trail + S3 bucket (optional - if not already present)
- SNS Topic in the management account
- EventBridge event bus in the management account
- EventBridge event rule in the management account
- CloudFormation StackSet that deploys the following resources to in each chosen member account:
  - EventBridge event rule
  - Other supporting resources

## Example Usage

Run the following command to generate the basic `terraform.tfvars` file:

```bash
cat <<EOF > terraform.tfvars
deploy_to_organization = false
include_organizational_units = ["ou-s8qf-092b7iur"]
monitored_events = ["RedeemPromoCode", "CreateSecurityGroup"]
EOF
```

Then, to deploy the resources, simply run `terraform apply`

The above example will deploy the automation to all accounts under the `ou-s8qf-092b7iur` organizational unit (OU), and will monitor (and alert) all events of redeeming a Credit and creating a security group.

You can modify the above command (or the generated `terraform.tfvars` file) to deploy to your specified OUs.

You can also deploy the automation to the entire organization (all accounts) by specifying `deploy_to_organization = true`.

> **Note:** You must configure your console credentials with proper permissions on the management account of your AWS organization

## Known Issues

In some cases, running `terraform destroy` might fail (for example if there is a `suspended` account in the organization). If this happens, You'll need to delete all Stack Instances from the CloudFormation StackSet manually through AWS console. Perform the following:
1. Login to the **management account** of your AWS organization
2. Go to **CloudFormation** service
3. Go to **StackSets**
4. Click on the stuck StackSet (starting with `organizational-events-notifier`)
5. Click on **Actions** and choose **Delete stacks from StackSet**
6. For **AWS OU ID** provide  one of the following:
   - If deployed the automation to the entire organization, provide the ID of your organization (for example: `r-s8qf`)
   - If deployed the automation to specific organizational units (OUs), provide the ID of all OUs
7. For **Specify regions** click on **Add all regions**
8. Under **Deployment options**, use the following values:
   - Maximum concurrent accounts: `Percentage` - `100`
   - Failure tolerance: `Percentage` - `100`
   - Region Concurrency: `Parallel`
9.  Keep all other default values
10. Proceed to delete the StackSet Instances
11. In the StackSet page, go to **Stack Instances** tab and make sure that it's empty
12. Run `terraform destroy` again to delete all other resources

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.59 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.59.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack_set.eventbridge_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set_instance.eventbridge_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_cloudtrail.management_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_event_bus.cross_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus) | resource |
| [aws_cloudwatch_event_bus_policy.cross_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus_policy) | resource |
| [aws_cloudwatch_event_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_s3_bucket.trail_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.trail_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cross_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assume_role_arn"></a> [assume\_role\_arn](#input\_assume\_role\_arn) | ARN of the IAM Role to assume in the member account | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region to deploy all resources | `string` | `"us-east-1"` | no |
| <a name="input_cloudtrail_trail_name"></a> [cloudtrail\_trail\_name](#input\_cloudtrail\_trail\_name) | Name of the management-events CloudTrail Trail to create | `string` | `"management-events"` | no |
| <a name="input_create_cloudtrail_trail"></a> [create\_cloudtrail\_trail](#input\_create\_cloudtrail\_trail) | Whether to create a new Cloudtrail Trail (and S3 bucket) to store manamgenet events. Choose false if you already have one. | `bool` | `false` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Tags to apply across all resources handled by this provider | `map(string)` | <pre>{<br>  "Terraform": "True"<br>}</pre> | no |
| <a name="input_deploy_to_organization"></a> [deploy\_to\_organization](#input\_deploy\_to\_organization) | Whether to deploy the automation to the main OU of the organization (all AWS accounts in the organization) | `bool` | `true` | no |
| <a name="input_email_recipients"></a> [email\_recipients](#input\_email\_recipients) | List of email addresses that should receive alerts for the monitored events | `list(string)` | n/a | yes |
| <a name="input_include_organizational_units"></a> [include\_organizational\_units](#input\_include\_organizational\_units) | List of AWS organizational unit IDs to include and deploy the automation to (if `deploy_to_organization` is set to `false`) | `list(string)` | `[]` | no |
| <a name="input_monitored_events"></a> [monitored\_events](#input\_monitored\_events) | List of AWS events that should be monitored across the organization (for example: `RedeemPromoCode`) | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the tool/project | `string` | `"organizational-events-notifier"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->