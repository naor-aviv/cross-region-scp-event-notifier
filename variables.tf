variable "aws_region" {
  description = "AWS Region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "assume_role_arn" {
  description = "ARN of the IAM Role to assume in the member account"
  type        = string
  default     = null
}

variable "default_tags" {
  description = "Tags to apply across all resources handled by this provider"
  type        = map(string)
  default = {
    Terraform = "True"
  }
}

variable "project_name" {
  description = "Name of the tool/project"
  type        = string
  default     = "organizational-events-notifier"
}

variable "create_cloudtrail_trail" {
  description = "Whether to create a new Cloudtrail Trail (and S3 bucket) to store manamgenet events. Choose false if you already have one."
  type        = bool
  default     = false
}

variable "cloudtrail_trail_name" {
  description = "Name of the management-events CloudTrail Trail to create"
  type        = string
  default     = "management-events"
}

variable "deploy_to_organization" {
  description = "Whether to deploy the automation to the main OU of the organization (all AWS accounts in the organization)"
  type        = bool
  default     = true
}

variable "include_organizational_units" {
  description = "List of AWS organizational unit IDs to include and deploy the automation to (if `deploy_to_organization` is set to `false`)"
  type        = list(string)
  default     = []
}

variable "monitored_events" {
  description = "List of AWS events that should be monitored across the organization (for example: `RedeemPromoCode`)"
  type        = list(string)
}

variable "email_recipients" {
  description = "List of email addresses that should receive alerts for the monitored events"
  type        = list(string)
}