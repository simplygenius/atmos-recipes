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

variable "cpu" {
  description = "The cpu value for fargate tasks"
  default = ""
}

variable "memory" {
  description = "The memory value for fargate tasks"
  default = ""
}

variable "containers_template" {
  description = "The template for the containers in the task definition"
}

variable "create_repository" {
  description = "Enable creating an ECR repo"
  default = 1
}

variable "image_expiry_days" {
  description = "Clean up images older than this number of days"
  default = 30
}

variable "launch_type" {
  description = "The launch type for the ecs service.  Can be one of FARGATE or EC2"
  default = "FARGATE"
}

variable "network_mode" {
  description = "The network mode for ecs tasks"
  default = "awsvpc"
}

variable "volumes" {
  description = "The volumes to use for the containers"
  type = "list"
  default = []
}
