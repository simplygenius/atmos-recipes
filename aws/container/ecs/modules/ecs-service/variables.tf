variable "atmos_env" {
  description = "The atmos environment"
}

variable "global_name_prefix" {
  description = <<-EOF
    The global name prefix for disambiguating resource names that have a global
    scope (e.g. s3 bucket names)
EOF


  default = ""
}

variable "local_name_prefix" {
  description = <<-EOF
    The local name prefix for disambiguating resource names that have a local scope
    (e.g. when running multiple environments in the same account)
EOF


  default = ""
}

variable "name" {
  description = "The component name"
}

variable "region" {
  description = "The aws region"
}

variable "ecs_cluster_arn" {
  description = "The ECS cluster to deploy containers into"
}

variable "cpu" {
  description = "The cpu value for fargate tasks"
  default     = ""
}

variable "memory" {
  description = "The memory value for fargate tasks"
  default     = ""
}

variable "port" {
  description = "The service port"
  default     = 80
}

variable "vpc_id" {
  description = "The vpc for the components security group"
}

variable "subnet_ids" {
  description = "The subnet ids for components that need them - can be public or private"
  type        = list(string)
}

variable "security_groups" {
  description = "The security groups associated with the instance"
  type        = list(string)
  default     = []
}

variable "integrate_with_lb" {
  description = <<-EOF
    Flag to enable LB integration.  Can't use elb_id/alb_target_group_id as
    they make counts computed
EOF


  default = 0
}

variable "alb_target_group_id" {
  description = <<-EOF
    The ALB target group id to load balance the service with
EOF


  default = ""
}

variable "containers_template" {
  description = "The template for the containers in the task definition"
}

variable "container_count" {
  description = "The desired count of containers"
  default     = 2
}

variable "deployment_minimum_healthy_percent" {
  description = "The minimum percent of nodes to keep up when deploying"
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "The maximum percent of nodes to spin up when deploying"
  default     = 200
}

variable "create_repository" {
  description = "Enable creating an ECR repo"
  default     = 1
}

variable "image_expiry_count" {
  description = "Only keep the most recent images.  Set to -1 to never expire"
  default     = 100
}

variable "cloudwatch_alarm_target" {
  description = "The target of cloudwatch alarm_actions, usually an sns topic"
  default     = ""
}

variable "launch_type" {
  description = "The launch type for the ecs service.  Can be one of FARGATE or EC2"
  default     = "FARGATE"
}

variable "network_mode" {
  description = "The network mode for ecs tasks"
  default     = "awsvpc"
}

variable "volumes" {
  description = "The volumes to use for the containers"
  type        = list(string)
  default     = []
}

