# Bedrock Agent Configuration for Natural Language to SQL Translation

# Bedrock Agent for SQL Generation
resource "aws_bedrockagent_agent" "athena_translator" {
  agent_name = "${local.project_name}-athena-translator"
  description = "Agent that translates natural language queries into SQL for structured data sources"
  
  # Agent configuration for SQL generation
  agent_resource_role_arn = aws_iam_role.bedrock_agent_role.arn
  
  # Foundation model for the agent
  foundation_model = local.mcp_client_model_arn
  
  # Agent configuration
  idle_session_ttl_in_seconds = 3600 # 1 hour
  
  # Agent configuration for SQL generation
  instruction = <<-EOT
  You are an Athena PrestoDB translation agent that converts natural language queries into Athena PrestoDB statements.
  You do not have access to the data, your only job is to generate the SQL query.
  
  Your task is to:
  1. Understand the user's natural language query
  2. Generate appropriate Athena PrestoDB queries based on the schema below
  3. Ensure the Athena PrestoDB statement is syntactically correct and follows best practices
  
  Table: "assets"
  
  Table "assets" schema:
  - "tag"
  - "type"
  - "building"
  - "replacement_asset_value"
  - "installation_date"
  - "planned_replacement_date"
  - "estimated_end_of_life"
  - "remaining_useful_life"
  - "estimated_replacement_cost"
  - "estimated_replacement_date"
  - "warranty_expiration_date"
  - "lifetime_maintenance_cost"
  - "last_12_months_maintenance_cost"
  - "average_annual_maintenance_cost"
  - "mc_rav_percentage"
  - "manufacturer"
  - "date_purchased"
  - "filter_size"
  - "vin_number"
  - "last_maintenance_date"
  - "maintenance_cost"
  - "notes"


  Take in account that all collumns are of type string. So for date or numeric value searches you will have to use the like operators.
  Always generate valid SQL Athena PrestoDB. DO NOT RETURN ANYTHING ELSE, JUST PRESTO DB ATHENA SQL.

  EXAMPLE #1:
  Input: "What is the total maintenance cost for all assets?"
  Output: "SELECT SUM(maintenance_cost) FROM assets"

  EXAMPLE #2:
  Input: "Give me all the assets that have a maintenance cost greater than 1000"
  Output: "SELECT * FROM assets WHERE CAST(maintenance_cost AS DOUBLE) > 1000"

  EXAMPLE #3:
  Input: "Show me all assets purchased in 2022"
  Output: "SELECT * FROM assets WHERE date_purchased LIKE '%2022%'"

  EXAMPLE #4:
  Input: "What is the average maintenance cost of assets with maintenance in 2021?"
  Output: "SELECT AVG(CAST(maintenance_cost AS DOUBLE)) FROM assets WHERE last_maintenance_date LIKE '%2021%'"

  RETURN ONLY THE ATHENA PRESTO SQL QUERY, NO OTHER TEXT. I REPEAT, NO OTHER TEXT.
  EOT
  
  tags = local.tags
}

# Bedrock Agent Alias
resource "aws_bedrockagent_agent_alias" "athena_translator_alias" {
  agent_alias_name = "${local.project_name}-athena-translator-alias"
  agent_id = aws_bedrockagent_agent.athena_translator.id
  description = "Production alias for Athena SQL translator agent"
  
  tags = local.tags
}

# IAM Role for Bedrock Agent
resource "aws_iam_role" "bedrock_agent_role" {
  name = "${local.project_name}-bedrock-agent-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.tags
}

# IAM Policy for Bedrock Agent
resource "aws_iam_role_policy" "bedrock_agent_policy" {
  name = "${local.project_name}-bedrock-agent-policy"
  role = aws_iam_role.bedrock_agent_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:*"
        ]
        Resource = [
          "*"
        ]
      },
    ]
  })
}
