data "aws_iam_policy_document" "assume_role_policy" {
  dynamic "statement" {
    for_each = var.assume_role_statements
    content {
      sid     = statement.value.sid
      actions = statement.value.actions
      effect  = statement.value.effect

      dynamic "principals" {
        for_each = statement.value.principals != null ? [statement.value.principals] : []
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = statement.value.not_principals != null ? [statement.value.not_principals] : []
        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = coalesce(statement.value.conditions, [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role" "iam_role" {
  name               = "${var.iam_role_name}-${terraform.workspace}-role"
  description        = "${var.iam_role_name}-${terraform.workspace}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies

  tags = {
    Project     = var.project_name
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "policy_document" {
  dynamic "statement" {
    for_each = var.policy_statements != null ? var.policy_statements : []
    content {
      sid     = statement.value.sid
      actions = statement.value.actions
      effect  = statement.value.effect

      dynamic "principals" {
        for_each = statement.value.principals != null ? [statement.value.principals] : []
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = statement.value.not_principals != null ? [statement.value.not_principals] : []
        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = coalesce(statement.value.conditions, [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }

      not_actions = statement.value.not_actions
      resources   = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy" "iam_role_policy" {
  count  = length(var.policy_statements) > 0 ? 1 : 0
  name   = "${var.iam_role_name}-${terraform.workspace}-policy"
  role   = aws_iam_role.iam_role.id
  policy = data.aws_iam_policy_document.policy_document.json
}
