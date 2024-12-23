## Adding provider
provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

# data "aws_vpc" "craft_vpc_id" {
#   id = var.vpc_id
# }

locals {
  region = "ca-central-1"
  ecs_cluster_name   = "ecs-cluster-${var.env}-${var.region_short_name}"
  ecs_service_name   = "ecs-service-${var.env}-${var.region_short_name}"
  ecs_task_def_name  = "ecs-task-def-${var.env}-${var.region_short_name}"
  aws_service_discovery_http_namespace = "ecs_sd-${var.env}-${var.region_short_name}"
  ecs_alb_name      = "ecs-alb-${var.env}-${var.region_short_name}"  

  vpc_cidr = "10.128.223.0/24"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  container_name = "craft-cms-container"
  container_port = 8080

}

################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  //source = "git::https://github.com/sarabbrainridge/terraform-modules.git//modules/cluster?ref=main"
  source = "./modules/cluster"

  cluster_name = local.ecs_cluster_name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = {
    Name       = local.ecs_cluster_name
  }
}

################################################################################
# Service
################################################################################

module "ecs_service" {
  //source = "git::https://github.com/sarabbrainridge/terraform-modules.git//modules/service?ref=main"
  source = "./modules/service"
  name        = local.ecs_service_name
  cluster_arn = module.ecs_cluster.arn

  enable_autoscaling = false

  cpu    = 1024
  memory = 3072

  # Enables ECS Exec
  enable_execute_command = true

  # Container definition(s)
  container_definitions = {

      health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:${local.container_port}/ || exit 1"]
          }

    (local.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "864899849560.dkr.ecr.ca-central-1.amazonaws.com/craftcms:craftcms-package-8.4-latest"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false

      enable_cloudwatch_logging = true

      memory_reservation = 100
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["craft_cms_ecs"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = var.subnet_ids
  security_group_rules = {
    alb_ingress_8080 = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  service_tags = {
    "ServiceTag" = "Tag on service level"
  }

  tags = {
    Name       = local.ecs_service_name
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.ecs_alb_name

  internal = true

  load_balancer_type = "application"

  vpc_id  = var.vpc_id
  subnets = var.subnet_ids

  # For example only
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = local.vpc_cidr
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = local.vpc_cidr
    }
  }

  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "craft_cms_ecs"
      }
    }
  }

  target_groups = {
    craft_cms_ecs = {
      backend_protocol                  = "HTTP"
      port                              = "8080"
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 40
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # There's nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
  }

  tags = {
    Name       = local.ecs_alb_name
  }
}