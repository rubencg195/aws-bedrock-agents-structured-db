locals {
    project_name           = "mcp-demo"

    # VPC Configuration
    vpc_name               = local.project_name
    cidr_block             = "10.0.0.0/16"
    enable_dns_support     = true
    enable_dns_hostnames   = true
    destination_cidr_block = "0.0.0.0/0"
    number_of_subnets      = 4
    flow_logs_retention    = 30


    # Knowledge Base Configuration
    knowledge_base_bucket_name = "${local.project_name}-knowledge-base"
    knowledge_base_local_folder = "knowledge-bases"
    knowledge_base_csv_files = [
        # "knowledge-base-1.csv",
        "asset-replacements.csv",
        # "asset-replacements.csv.metadata.json",
        # "asset-replacements.xlsm"
    ]
    knowledge_base_input_data_prefix = "input-data/"
    mcp_client_model_arn   = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-3-7-sonnet-20250219-v1:0"
    # mcp_client_model_arn   = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-sonnet-4-20250514-v1:0"
    # mcp_client_model_arn   = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
    knowledge_base_bucket_storage_uri = "s3://${aws_s3_bucket.knowledge_base_storage.bucket}/"

    # RDS Configuration
    rds_instance_class = "db.r6g.large"
    rds_allocated_storage = 20
    rds_max_allocated_storage = 100
    rds_backup_retention_period = 7
    rds_embedding_dimensions = 1024

    website_assets = {
    "index.html" = {
      source       = "${path.module}/website/index.html"
      content_type = "text/html"
    }
    "style.css" = {
      source       = "${path.module}/website/style.css"
      content_type = "text/css"
    }
    "index.js" = {
      source       = "${path.module}/website/index.js"
      content_type = "application/javascript"
    }
  }

    tags = {
        Owner      = "rubencg195@hotmail.com"
        Project     = local.project_name
        Environment = "dev"
        ManagedBy   = "Terraform"
        Role        = "terraform"
    }
}