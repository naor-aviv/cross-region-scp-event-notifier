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
  default     = "SCP-organizational-events-notifier"
}

variable "deploy_to_organization" {
  description = "Whether to deploy the automation to the main OU of the organization (all AWS accounts in the organization)"
  type        = bool
  default     = false
}

variable "include_organizational_units" {
  description = "List of AWS organizational unit IDs to include and deploy the automation to (if `deploy_to_organization` is set to `false`)"
  type        = list(string)
  default     = ["ou-s8qf-092b7iur"]
}


# Function variables
variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default = "scp-Cross-event-notifier"
}
variable "function_description" {
  description = "Description of the Lambda function"
  type        = string
  default = "Lambda function to notify user when SCP blocks action"
}
variable "function_timeout" {
  description = "The amount of time your Lambda Function has to run in seconds"
  type        = number
  default = 60
}
variable "function_mem" {
  type        = number
  description = "Lambda function memory size"
  default = 128
}
variable "script_name" {
  type        = string
  description = "name of the python script"
  default = "scp-Cross-event-notifier"
}

variable "lambda_environment_variables" {
  type = map(string)
  default = {
    SES_SOURCE = "naor@terasky.com"
  }
}

variable "log_group_retention" {
  description = "CloudWatch log group retention days"
  type        = number
  default = 0
}
