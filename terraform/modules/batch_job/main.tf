resource "aws_batch_compute_environment" "batch_compute_environment" {
  name         = "${var.batch_job_name}-batch-environment-${terraform.workspace}"
  region       = var.aws_region
  type         = var.compute_environment_type
  service_role = var.batch_service_role_arn
  state        = var.compute_environment_state

  tags = {
    Project     = var.project_name
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }

  dynamic "compute_resources" {
    for_each = var.compute_environment_type == "MANAGED" && var.compute_resources != null ? [var.compute_resources] : []
    content {
      type               = compute_resources.value.type
      max_vcpus          = compute_resources.value.max_vcpus
      security_group_ids = compute_resources.value.security_group_ids
      subnets            = compute_resources.value.subnets

      allocation_strategy = compute_resources.value.allocation_strategy
      bid_percentage      = compute_resources.value.bid_percentage
      desired_vcpus       = compute_resources.value.desired_vcpus
      ec2_key_pair        = compute_resources.value.ec2_key_pair
      instance_role       = compute_resources.value.instance_role
      instance_type       = compute_resources.value.instance_type
      min_vcpus           = compute_resources.value.min_vcpus
      placement_group     = compute_resources.value.placement_group
      spot_iam_fleet_role = compute_resources.value.spot_iam_fleet_role
      tags                = compute_resources.value.tags

      dynamic "ec2_configuration" {
        for_each = compute_resources.value.ec2_configuration != null ? [compute_resources.value.ec2_configuration] : []
        content {
          image_id_override = ec2_configuration.value.image_id_override
          image_type        = ec2_configuration.value.image_type
        }
      }

      dynamic "launch_template" {
        for_each = compute_resources.value.launch_template != null ? [compute_resources.value.launch_template] : []
        content {
          launch_template_id   = launch_template.value.launch_template_id
          launch_template_name = launch_template.value.launch_template_name
          version              = launch_template.value.version
        }
      }
    }
  }

  dynamic "eks_configuration" {
    for_each = var.eks_configuration != null ? [var.eks_configuration] : []
    content {
      eks_cluster_arn      = eks_configuration.value.eks_cluster_arn
      kubernetes_namespace = eks_configuration.value.kubernetes_namespace
    }
  }
}

resource "aws_batch_job_queue" "batch_job_queue" {
  name     = "${var.batch_job_name}-batch-queue-${terraform.workspace}"
  region   = var.aws_region
  state    = var.job_queue_state
  priority = var.job_queue_priority

  tags = {
    Project     = var.project_name
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.batch_compute_environment.arn
  }
}
