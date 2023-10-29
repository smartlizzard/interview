variable "workers_role_arns" {
  type        = list(string)
  description = "List of Role ARNs of the worker nodes"
  default     = []
}

variable "apply_config_map_aws_auth" {
  type        = bool
  default     = true
  description = "Whether to apply the ConfigMap to allow worker nodes to join the EKS cluster and allow additional users, accounts and roles to acces the cluster"
}

variable "wait_for_cluster_command" {
  type        = string
  default     = "curl --silent --fail --retry 60 --retry-delay 5 --insecure --output /dev/null $ENDPOINT/healthz"
  description = "`local-exec` command to execute to determine if the EKS cluster is healthy. Cluster endpoint are available as environment variable `ENDPOINT`"
}

variable "kubernetes_config_map_ignore_role_changes" {
  type        = bool
  default     = true
  description = "Set to `true` to ignore IAM role changes in the Kubernetes Auth ConfigMap"
}

variable "map_additional_iam_users" {
  description = "Additional IAM users to add to `config-map-aws-auth` ConfigMap"

  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

 
    default = [{
        userarn = "arn:aws:iam::659664721075:user/rpradhan"
        username = "rpradhan"
        groups = [
            "system:masters"
        ]
    }]
}

variable "map_additional_aws_accounts" {
  description = "Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap"
  type        = list(string)
  default     = []
}

variable "map_additional_iam_roles" {
  description = "Additional IAM roles to add to `config-map-aws-auth` ConfigMap"

  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

    default = []
}

variable "local_exec_interpreter" {
  type        = list(string)
  default     = []    #["/bin/sh", "-c"]
  description = "shell to use for local_exec"
}