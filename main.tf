data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}


module "module_aws_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "blog_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}


module "module_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.1.0"

  name = "hp-autoscaling"

  min_size  = 1
  max_size  = 3
  
  vpc_zone_identifier    = module.module_aws_vpc.public_subnets
  security_groups = [module.module_aws_security_group.security_group_id]
  image_id               = data.aws_ami.app_ami.id
  instance_type          = var.instance_type
  traffic_source_attachments = {
    traffic_source = {
    identifier = module.module_aws_alb.target_groups.hp-instance.arn
    type       = "elbv2"
  }
  }
}

module "module_aws_alb" {
  source = "terraform-aws-modules/alb/aws"

  name            = "blog-alb"
  vpc_id          = module.module_aws_vpc.vpc_id
  subnets         = module.module_aws_vpc.public_subnets
  security_groups = [module.module_aws_security_group.security_group_id]

  listeners = {
    hp-http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "hp-instance"
      }
    }
    
  }

  target_groups = {
    hp-instance = {
      name_prefix      = "hp"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      create_attachment = false
    }
  }

  tags = {
    Environment = "Development"
    Project     = "Huma_Project"
  }
}

module "module_aws_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"
  name = "blog_anees_sg"

  vpc_id      = module.module_aws_vpc.vpc_id

  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_rules            = ["https-443-tcp", "http-80-tcp"]

  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_rules            = ["all-all"]

}
