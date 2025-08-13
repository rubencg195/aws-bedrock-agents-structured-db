# Amazon Athena Workgroup Configuration

# S3 Bucket for Athena Query Results
resource "aws_s3_bucket" "athena_query_results" {
  bucket = "${local.project_name}-athena-query-results"
  
  tags = local.tags
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "athena_query_results_versioning" {
  bucket = aws_s3_bucket.athena_query_results.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "athena_query_results_encryption" {
  bucket = aws_s3_bucket.athena_query_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "athena_query_results_public_access_block" {
  bucket = aws_s3_bucket.athena_query_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Ownership Control
resource "aws_s3_bucket_ownership_controls" "athena_query_results_ownership" {
  bucket = aws_s3_bucket.athena_query_results.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "athena_query_results_lifecycle" {
  bucket = aws_s3_bucket.athena_query_results.id

  rule {
    id     = "cleanup_old_query_results"
    status = "Enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# S3 Bucket Policy for Athena
resource "aws_s3_bucket_policy" "athena_query_results_policy" {
  bucket = aws_s3_bucket.athena_query_results.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AthenaOutputLocation"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.athena_query_results.arn,
          "${aws_s3_bucket.athena_query_results.arn}/*"
        ]
      }
    ]
  })
}

# IAM Role for Athena
resource "aws_iam_role" "athena_role" {
  name = "${local.project_name}-athena-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.tags
}

# IAM Policy for Athena
resource "aws_iam_role_policy" "athena_policy" {
  name = "${local.project_name}-athena-policy"
  role = aws_iam_role.athena_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.athena_query_results.arn,
          "${aws_s3_bucket.athena_query_results.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.knowledge_base_input_data.arn,
          "${aws_s3_bucket.knowledge_base_input_data.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchGetPartition"
        ]
        Resource = "*"
      }
    ]
  })
}

# Athena Workgroup
resource "aws_athena_workgroup" "main" {
  name = "${local.project_name}-workgroup"
  description = "Main Athena workgroup for querying asset management and transaction data"
  
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results.bucket}/query-results/"
      
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
    
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    
    # Query timeout and memory settings
    bytes_scanned_cutoff_per_query = 1073741824  # 1 GB
    requester_pays_enabled         = false
  }
  
  tags = local.tags
}
