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
  instruction = file("${path.module}/bedrock-agent-instructions.txt")
  
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
