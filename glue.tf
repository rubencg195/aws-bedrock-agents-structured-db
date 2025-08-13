# AWS Glue Catalog and Crawler Configuration

# Custom CSV Classifier for Asset Data
resource "aws_glue_classifier" "asset_csv_classifier" {
  name = "${local.project_name}-asset-csv-classifier"
  
  csv_classifier {
    # Specify delimiter (comma for CSV)
    delimiter = ","
    
    # Quote character for text fields
    quote_symbol = "\""
    
    # Skip header row
    contains_header = "PRESENT"
  }
}

# Glue Database for Athena
resource "aws_glue_catalog_database" "asset_management" {
  name = "${local.project_name}_asset_management"
  description = "Database for asset management and transaction data"
  
  catalog_id = data.aws_caller_identity.current.account_id
  
  tags = local.tags
}

# Manually defined table with explicit schema
resource "aws_glue_catalog_table" "asset_data_table" {
  name          = "assets"
  database_name = aws_glue_catalog_database.asset_management.name
  
  # Define explicit schema with data types
  storage_descriptor {
    location = "s3://${aws_s3_bucket.knowledge_base_input_data.bucket}/${local.knowledge_base_input_data_prefix}/"
    
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    
    ser_de_info {
      name                  = "asset_csv_serde"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
      
      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "\""
        "skip.header.line.count" = "1"
      }
    }
    
    # Explicit column definitions with data types
    columns {
      name = "Tag"
      type = "string"
    }
    
    columns {
      name = "Type"
      type = "string"
    }
    
    columns {
      name = "Building"
      type = "string"
    }
    
    columns {
      name = "Replacement_Asset_Value"
      type = "string"
    }
    
    columns {
      name = "Installation_Date"
      type = "string"
    }
    
    columns {
      name = "Planned_Replacement_Date"
      type = "string"
    }
    
    columns {
      name = "Estimated_End_of_Life"
      type = "string"
    }
    
    columns {
      name = "Remaining_Useful_Life"
      type = "string"
    }
    
    columns {
      name = "Estimated_Replacement_Cost"
      type = "string"
    }
    
    columns {
      name = "Estimated_Replacement_Date"
      type = "string"
    }
    
    columns {
      name = "Warranty_Expiration_Date"
      type = "string"
    }
    
    columns {
      name = "Lifetime_Maintenance_Cost"
      type = "string"
    }
    
    columns {
      name = "Last_12_Months_Maintenance_Cost"
      type = "string"
    }
    
    columns {
      name = "Average_Annual_Maintenance_Cost"
      type = "string"
    }
    
    columns {
      name = "MC_RAV_Percentage"
      type = "string"
    }
    
    columns {
      name = "Manufacturer"
      type = "string"
    }
    
    columns {
      name = "Date_Purchased"
      type = "string"
    }
    
    columns {
      name = "Filter_Size"
      type = "string"
    }
    
    columns {
      name = "Vin_Number"
      type = "string"
    }
    
    columns {
      name = "Last_Maintenance_Date"
      type = "string"
    }
    
    columns {
      name = "Maintenance_Cost"
      type = "string"
    }
    
    columns {
      name = "Notes"
      type = "string"
    }
  }
  
  # Table properties
  parameters = {
    "classification" = "csv"
    "typeOfData"    = "file"
  }
}

# IAM Role for Glue Crawler
resource "aws_iam_role" "glue_crawler_role" {
  name = "${local.project_name}-glue-crawler-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.tags
}

# IAM Policy for Glue Crawler
resource "aws_iam_role_policy" "glue_crawler_policy" {
  name = "${local.project_name}-glue-crawler-policy"
  role = aws_iam_role.glue_crawler_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
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
          "glue:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}
