variable "region_short_name" {
  description = "Defining the region short name for naming convention"
  type = string
  default = "cc"
}

variable "env" {
  description = "Defining the env to differentiate the values"
  default = "lab"
}

variable "vpc_id" {
  description = "The ID of VPC which is unique and used to determin for subnet and network resources"
  default = "vpc-0d918cd659e10ed48"
}

variable "subnet_ids" {
  description = "Subnets ID associated with the task or service."
  type = list(string)
  default = ["subnet-0f146bbb3a2ef15ab","subnet-005660fe40bce333e"]
}

variable "vpc_cidr" {
  description = "The CIDR range of the VPC"
  type = string
  default = "10.128.223.0/24"
}

variable "container_port" {
  description = "Port where the container application is running"
  type = number
  default = 8080
}

variable "ecs_containerimage" {
  description = "The ecr image which will be deployed in the ECS container"
  default = "864899849560.dkr.ecr.ca-central-1.amazonaws.com/craftcms:craftcms-package-8.4-latest"  
}

variable "enable_cloudwatch_logging" {
  description = "Toggle value for cloudwatch logging. If enabled, will log the task"
  type = bool
  default = true
}

variable "enable_autoscaling" {
  description = "Toggle value for autoscaling. If enabled, will autoscale the task"
  type = bool
  default = false
}

variable "enable_execute_command" {
  description = "Toggle value for execute command. If enabled, will execute the command"
  type = bool
  default = true
}