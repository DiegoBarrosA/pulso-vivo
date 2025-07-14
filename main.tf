# Pulso Vivo API Gateway - Terraform Configuration
# =============================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "ec2_instance_ip" {
  description = "IP privada de la instancia EC2"
  type        = string
  default     = "10.0.1.100"
}

variable "azure_tenant_id" {
  description = "Azure AD B2C Tenant ID"
  type        = string
  default     = "82c6cf20-e689-4aa9-bedf-7acaf7c4ead7"
}

variable "azure_policy" {
  description = "Azure AD B2C Policy Name"
  type        = string
  default     = "b2c_1_pulso_vivo_register_and_login"
}

variable "azure_client_id" {
  description = "Azure AD B2C Client ID"
  type        = string
  default     = "7549ac9c-9294-4bb3-98d6-752d12b13d81"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

# Provider
provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC y Subnet (usar las existentes o crear nuevas)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group para NLB
resource "aws_security_group" "nlb_sg" {
  name        = "pulso-vivo-nlb-sg"
  description = "Security group for Pulso Vivo NLB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8081
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pulso-vivo-nlb-sg"
  }
}

# Network Load Balancer
resource "aws_lb" "pulso_vivo_nlb" {
  name               = "pulso-vivo-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = {
    Environment = "production"
    Project     = "pulso-vivo"
  }
}

# Target Groups
resource "aws_lb_target_group" "sales_tg" {
  name     = "pulso-vivo-sales-tg"
  port     = 8081
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "pulso-vivo-sales-tg"
  }
}

resource "aws_lb_target_group" "inventory_tg" {
  name     = "pulso-vivo-inventory-tg"
  port     = 8083
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "pulso-vivo-inventory-tg"
  }
}

resource "aws_lb_target_group" "promotions_tg" {
  name     = "pulso-vivo-promotions-tg"
  port     = 8085
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "pulso-vivo-promotions-tg"
  }
}

resource "aws_lb_target_group" "stock_tg" {
  name     = "pulso-vivo-stock-tg"
  port     = 8084
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "pulso-vivo-stock-tg"
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "sales_tg_attachment" {
  target_group_arn = aws_lb_target_group.sales_tg.arn
  target_id        = var.ec2_instance_ip
  port             = 8081
}

resource "aws_lb_target_group_attachment" "inventory_tg_attachment" {
  target_group_arn = aws_lb_target_group.inventory_tg.arn
  target_id        = var.ec2_instance_ip
  port             = 8083
}

resource "aws_lb_target_group_attachment" "promotions_tg_attachment" {
  target_group_arn = aws_lb_target_group.promotions_tg.arn
  target_id        = var.ec2_instance_ip
  port             = 8085
}

resource "aws_lb_target_group_attachment" "stock_tg_attachment" {
  target_group_arn = aws_lb_target_group.stock_tg.arn
  target_id        = var.ec2_instance_ip
  port             = 8084
}

# Listeners
resource "aws_lb_listener" "sales_listener" {
  load_balancer_arn = aws_lb.pulso_vivo_nlb.arn
  port              = "8081"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sales_tg.arn
  }
}

resource "aws_lb_listener" "inventory_listener" {
  load_balancer_arn = aws_lb.pulso_vivo_nlb.arn
  port              = "8083"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.inventory_tg.arn
  }
}

resource "aws_lb_listener" "promotions_listener" {
  load_balancer_arn = aws_lb.pulso_vivo_nlb.arn
  port              = "8085"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.promotions_tg.arn
  }
}

resource "aws_lb_listener" "stock_listener" {
  load_balancer_arn = aws_lb.pulso_vivo_nlb.arn
  port              = "8084"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.stock_tg.arn
  }
}

# VPC Link
resource "aws_api_gateway_vpc_link" "pulso_vivo_vpc_link" {
  name        = "pulso-vivo-vpc-link"
  description = "VPC Link para Pulso Vivo microservices"
  target_arns = [aws_lb.pulso_vivo_nlb.arn]
}

# API Gateway
resource "aws_api_gateway_rest_api" "pulso_vivo_api" {
  name        = "pulso-vivo-api"
  description = "API Gateway para sistema Pulso Vivo con microservicios Kafka"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# JWT Authorizer
resource "aws_api_gateway_authorizer" "azure_b2c_authorizer" {
  name                   = "AzureADB2CJWTAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.pulso_vivo_api.id
  type                   = "JWT"
  identity_source        = "method.request.header.Authorization"
  
  # Para JWT authorizer, necesitamos configurar el issuer y audience
  # Esto se hace mediante la configuración del authorizer
}

# Recursos
resource "aws_api_gateway_resource" "sales_resource" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  parent_id   = aws_api_gateway_rest_api.pulso_vivo_api.root_resource_id
  path_part   = "sales"
}

resource "aws_api_gateway_resource" "inventory_resource" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  parent_id   = aws_api_gateway_rest_api.pulso_vivo_api.root_resource_id
  path_part   = "inventory"
}

resource "aws_api_gateway_resource" "promotions_resource" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  parent_id   = aws_api_gateway_rest_api.pulso_vivo_api.root_resource_id
  path_part   = "promotions"
}

resource "aws_api_gateway_resource" "stock_resource" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  parent_id   = aws_api_gateway_rest_api.pulso_vivo_api.root_resource_id
  path_part   = "stock"
}

# Métodos GET para Sales
resource "aws_api_gateway_method" "sales_get" {
  rest_api_id   = aws_api_gateway_rest_api.pulso_vivo_api.id
  resource_id   = aws_api_gateway_resource.sales_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.azure_b2c_authorizer.id
}

resource "aws_api_gateway_integration" "sales_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  resource_id = aws_api_gateway_resource.sales_resource.id
  http_method = aws_api_gateway_method.sales_get.http_method

  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.ec2_instance_ip}:8081/sales"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.pulso_vivo_vpc_link.id
}

# Métodos POST para Sales
resource "aws_api_gateway_method" "sales_post" {
  rest_api_id   = aws_api_gateway_rest_api.pulso_vivo_api.id
  resource_id   = aws_api_gateway_resource.sales_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.azure_b2c_authorizer.id
}

resource "aws_api_gateway_integration" "sales_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  resource_id = aws_api_gateway_resource.sales_resource.id
  http_method = aws_api_gateway_method.sales_post.http_method

  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.ec2_instance_ip}:8081/sales"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.pulso_vivo_vpc_link.id
}

# OPTIONS para CORS
resource "aws_api_gateway_method" "sales_options" {
  rest_api_id   = aws_api_gateway_rest_api.pulso_vivo_api.id
  resource_id   = aws_api_gateway_resource.sales_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sales_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  resource_id = aws_api_gateway_resource.sales_resource.id
  http_method = aws_api_gateway_method.sales_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "sales_options_response" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  resource_id = aws_api_gateway_resource.sales_resource.id
  http_method = aws_api_gateway_method.sales_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "sales_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  resource_id = aws_api_gateway_resource.sales_resource.id
  http_method = aws_api_gateway_method.sales_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "pulso_vivo_waf" {
  name  = "PulsoVivoAPIProtection"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }

    action {
      block {}
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }

    action {
      block {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "PulsoVivoWAF"
    sampled_requests_enabled   = true
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.pulso_vivo_api.id}"
  retention_in_days = 30
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "pulso_vivo_deployment" {
  depends_on = [
    aws_api_gateway_method.sales_get,
    aws_api_gateway_method.sales_post,
    aws_api_gateway_integration.sales_get_integration,
    aws_api_gateway_integration.sales_post_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  stage_name  = "prod"
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.pulso_vivo_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.pulso_vivo_api.id
  stage_name    = "prod"

  xray_tracing_enabled = true

  depends_on = [aws_cloudwatch_log_group.api_gateway_logs]
}

# Method Settings
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.pulso_vivo_api.id
  stage_name  = aws_api_gateway_stage.prod_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level         = "INFO"
    data_trace_enabled    = true
    throttling_rate_limit = 100
    throttling_burst_limit = 200
  }
}

# Outputs
output "api_gateway_url" {
  description = "URL del API Gateway"
  value       = "https://${aws_api_gateway_rest_api.pulso_vivo_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/prod"
}

output "api_gateway_id" {
  description = "ID del API Gateway"
  value       = aws_api_gateway_rest_api.pulso_vivo_api.id
}

output "vpc_link_id" {
  description = "ID del VPC Link"
  value       = aws_api_gateway_vpc_link.pulso_vivo_vpc_link.id
}

output "nlb_arn" {
  description = "ARN del Network Load Balancer"
  value       = aws_lb.pulso_vivo_nlb.arn
}

output "waf_web_acl_arn" {
  description = "ARN del Web ACL"
  value       = aws_wafv2_web_acl.pulso_vivo_waf.arn
}
