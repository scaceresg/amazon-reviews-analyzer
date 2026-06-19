variable "iam_role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "force_detach_policies" {
  description = "Whether to force detach policies from the role before deleting"
  type        = bool
  default     = true
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (900–43200)"
  type        = number
  default     = 3600
}

variable "assume_role_statements" {
  description = <<EOF
    Statements for the IAM role trust policy (who can assume this role)
    For example:
    assume_role_statements = [
      {
        actions = ["sts:AssumeRole"]
        effect  = "Allow"
        principals = {
          type        = "Service"
          identifiers = ["ecs-tasks.amazonaws.com"]
        }
        conditions = [
          {
            test     = "StringEquals"
            variable = "aws:SourceAccount"
            values   = [local.account_id]
          }
        ]
      }
    ]
    EOF
  type = list(object({
    sid     = optional(string)
    actions = optional(list(string))
    effect  = string
    principals = optional(object({
      type        = string
      identifiers = list(string)
    }))
    not_principals = optional(object({
      type        = string
      identifiers = list(string)
    }))
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })))
  }))
}

variable "policy_statements" {
  description = <<EOF
  Trust policy statements defining who can assume this role.
  Only principals/not_principals, conditions, and not_actions are optional.
  Example:
  [
    {
      sid     = "AllowBatch"
      actions = ["sts:AssumeRole"]
      effect  = "Allow"
      principals = {
        type        = "Service"
        identifiers = ["batch.amazonaws.com"]
      }
    },
    {
      sid     = "AllowGitHubOIDC"
      actions = ["sts:AssumeRoleWithWebIdentity"]
      effect  = "Allow"
      principals = {
        type        = "Federated"
        identifiers = ["arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"]
      }
      conditions = [
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values   = ["repo:<org>/<repo>:*"]
        }
      ]
    }
  ]
  EOF
  type = list(object({
    sid     = optional(string)
    actions = optional(list(string))
    effect  = string
    principals = optional(object({
      type        = string
      identifiers = list(string)
    }))
    not_principals = optional(object({
      type        = string
      identifiers = list(string)
    }))
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })))
    not_actions = optional(list(string))
    resources   = optional(list(string))
  }))
  default = null
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}
