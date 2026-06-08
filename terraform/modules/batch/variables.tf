variable "aws_region" {
  description = "AWS region where the batch job is deployed"
  type        = string
}

variable "batch_job_name" {
  description = "Name of the batch job. It will be concatenated with '-batch-job-' and the workspace."
  type        = string
}

variable "batch_service_role_arn" {
  description = "ARN of the batch service role"
  type        = string
  default     = null
}

variable "compute_environment_type" {
  description = "The type of the compute environment. It can be 'MANAGED' or 'UNMANAGED'"
  type        = string
}

variable "compute_environment_state" {
  description = "The state of the compute environment. It can be 'ENABLED' or 'DISABLED'"
  type        = string
  default     = "ENABLED"
}

variable "compute_resources" {
  description = <<EOF
    The details for the compute resources. Required if compute_environment_type is 'MANAGED'.
    For example:
    compute_resources = {
        type = "FARGATE"
        max_vcpus = 256
        security_group_ids = ["sg-01234567890123456"]
        subnets = ["subnet-01234567890123456", "subnet-01234567890123457"]
    }
    EOF
  type = object({
    type               = string
    max_vcpus          = number
    security_group_ids = list(string)
    subnets            = list(string)

    allocation_strategy = optional(string)
    bid_percentage      = optional(number)
    desired_vcpus       = optional(number)
    ec2_key_pair        = optional(string)
    instance_role       = optional(string)
    instance_type       = optional(list(string))
    min_vcpus           = optional(number)
    placement_group     = optional(string)
    spot_iam_fleet_role = optional(string)
    tags                = optional(map(string))

    ec2_configuration = optional(object({
      image_id_override = optional(string)
      image_type        = optional(string)
    }))

    launch_template = optional(object({
      launch_template_id   = optional(string)
      launch_template_name = optional(string)
      version              = optional(string)
    }))
  })
  default = null
}

variable "eks_configuration" {
  description = <<EOF
    The details for the EKS configuration.
    For example:
    eks_configuration = {
        eks_cluster_arn = "arn:aws:eks:us-east-1:123456789012:cluster/my-cluster"
        kubernetes_namespace = "my-namespace"
    }
    EOF
  type = object({
    eks_cluster_arn      = string
    kubernetes_namespace = string
  })
  default = null
}

variable "job_queue_priority" {
  description = "The priority of the job queue. It can be a number between 1 and 1000, where 1 is the highest priority and 1000 is the lowest priority."
  type        = number
  default     = 1
}

variable "job_queue_state" {
  description = "The state of the job queue. It can be 'ENABLED' or 'DISABLED'"
  type        = string
  default     = "ENABLED"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}