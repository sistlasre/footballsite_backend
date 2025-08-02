
# --------------------
# DynamoDB Table for User Information
# --------------------
resource "aws_dynamodb_table" "user_table" {
  name           = "${var.project_name}-users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
  attribute {
    name = "username"
    type = "S"
  }

  global_secondary_index {
    name            = "username-index"
    hash_key        = "username"
    projection_type = "ALL"
  }

  tags = {
    Name        = "User Table"
    Environment = "dev"
  }
}

# --------------------
# DynamoDB Table for Events
# --------------------
resource "aws_dynamodb_table" "project_table" {
  name           = "${var.project_name}-projects"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "event_id"

  attribute {
    name = "user_id"
    type = "S"
  }
  attribute {
    name = "date_updated"
    type = "S"
  }
  attribute {
    name = "event_id"
    type = "S"
  }

  global_secondary_index {
    name            = "event_id-index"
    hash_key        = "event_id"
    projection_type = "ALL"
  }

  local_secondary_index {
    name            = "date_updated-index"
    range_key       = "date_updated"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Events Table"
    Environment = "dev"
  }
}

# --------------------
# Lambda Function: Create User
# --------------------
resource "aws_lambda_function" "create_user" {
  function_name = "${var.project_name}-create-user"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "create_user.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/create_user.zip"
  source_code_hash = filebase64sha256("lambda/create_user.zip")

  environment {
    variables = {
      USER_TABLE = aws_dynamodb_table.user_table.name
    }
  }

  tags = {
    Name = "Create User Lambda"
  }
}

# --------------------
# Lambda Function: Sign-in User
# --------------------
resource "aws_lambda_function" "signin_user" {
  function_name = "${var.project_name}-signin-user"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "signin_user.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/signin_user.zip"
  source_code_hash = filebase64sha256("lambda/signin_user.zip")

  environment {
    variables = {
      USER_TABLE = aws_dynamodb_table.user_table.name
      JWT_SECRET = var.jwt_secret
    }
  }

  tags = {
    Name = "Sign-in User Lambda"
  }
}

# --------------------
# Lambda Function: Auth Middleware
# --------------------
resource "aws_lambda_function" "auth_middleware" {
  function_name = "${var.project_name}-auth-middleware"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "auth_middleware.lambda_handler"
  timeout       = 30
  memory_size   = 128

  filename         = "lambda/auth_middleware.zip"
  source_code_hash = filebase64sha256("lambda/auth_middleware.zip")

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }

  tags = {
    Name = "Auth Middleware Lambda"
  }
}

# --------------------
# Lambda Function: Create Project
# --------------------
resource "aws_lambda_function" "create_project" {
  function_name = "${var.project_name}-create-project"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "create_project.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/create_event.zip"
  source_code_hash = filebase64sha256("lambda/create_event.zip")

  environment {
    variables = {
      EVENTS_TABLE = aws_dynamodb_table.events_table.name
    }
  }

  tags = {
    Name = "Create Event Lambda"
  }
}

# --------------------
# Lambda Function: Delete Project
# --------------------
resource "aws_lambda_function" "delete_project" {
  function_name = "${var.project_name}-delete-project"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "delete_project.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/delete_project.zip"
  source_code_hash = filebase64sha256("lambda/delete_project.zip")

  environment {
    variables = {
      PROJECT_TABLE = aws_dynamodb_table.project_table.name
    }
  }

  tags = {
    Name = "Delete Project Lambda"
  }
}

# --------------------
# Lambda Function: Endpoints Dashboard
# --------------------
resource "aws_lambda_function" "endpoints_dashboard" {
  function_name = "${var.project_name}-endpoints-dashboard"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "endpoints_dashboard.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/endpoints_dashboard.zip"
  source_code_hash = filebase64sha256("lambda/endpoints_dashboard.zip")

  tags = {
    Name = "Endpoints Dashboard Lambda"
  }
}

# --------------------
# Lambda Function: Fetch User Events
# --------------------
resource "aws_lambda_function" "fetch_user_projects" {
  function_name = "${var.project_name}-fetch-user-projects"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "fetch_user_projects.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/fetch_user_projects.zip"
  source_code_hash = filebase64sha256("lambda/fetch_user_projects.zip")

  environment {
    variables = {
      PROJECT_TABLE = aws_dynamodb_table.project_table.name
      BOXES_TABLE   = aws_dynamodb_table.boxes_table.name
    }
  }

  tags = {
    Name = "Fetch User Projects Lambda"
  }
}

# --------------------
# Lambda Function: Fetch User Projects (No Token)
# --------------------
resource "aws_lambda_function" "fetch_user_projects_no_token" {
  function_name = "${var.project_name}-fetch-user-projects-no-token"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "fetch_user_projects_no_token.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/fetch_user_projects_no_token.zip"
  source_code_hash = filebase64sha256("lambda/fetch_user_projects_no_token.zip")

  environment {
    variables = {
      PROJECT_TABLE = aws_dynamodb_table.project_table.name
      BOXES_TABLE   = aws_dynamodb_table.boxes_table.name
    }
  }

  tags = {
    Name = "Fetch User Projects No Token Lambda"
  }
}

# --------------------
# Lambda Function: Fetch Project Details
# --------------------
resource "aws_lambda_function" "fetch_project_details" {
  function_name = "${var.project_name}-fetch-project-details"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "fetch_project_details.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/fetch_project_details.zip"
  source_code_hash = filebase64sha256("lambda/fetch_project_details.zip")

  environment {
    variables = {
      PROJECT_TABLE = aws_dynamodb_table.project_table.name
      BOXES_TABLE   = aws_dynamodb_table.boxes_table.name
      PARTS_TABLE_NEW = aws_dynamodb_table.parts_table_new.name
    }
  }

  tags = {
    Name = "Fetch Project Details Lambda"
  }
}

# --------------------
# Lambda Function: Fetch Box Details
# --------------------
resource "aws_lambda_function" "fetch_box_details" {
  function_name = "${var.project_name}-fetch-box-details"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "fetch_box_details.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/fetch_box_details.zip"
  source_code_hash = filebase64sha256("lambda/fetch_box_details.zip")

  environment {
    variables = {
      BOXES_TABLE = aws_dynamodb_table.boxes_table.name
      PARTS_TABLE_NEW = aws_dynamodb_table.parts_table_new.name
      IMAGES_TABLE = aws_dynamodb_table.images_table.name
    }
  }

  tags = {
    Name = "Fetch Box Details Lambda"
  }
}

# --------------------
# Lambda Function: Fetch Part Details
# --------------------
resource "aws_lambda_function" "fetch_part_details" {
  function_name = "${var.project_name}-fetch-part-details"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "fetch_part_details.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/fetch_part_details.zip"
  source_code_hash = filebase64sha256("lambda/fetch_part_details.zip")

  environment {
    variables = {
      PARTS_TABLE_NEW = aws_dynamodb_table.parts_table_new.name
      IMAGES_TABLE = aws_dynamodb_table.images_table.name
    }
  }

  tags = {
    Name = "Fetch Part Details Lambda"
  }
}

# --------------------
# Lambda Function: Create Part
# --------------------
resource "aws_lambda_function" "create_part" {
  function_name = "${var.project_name}-create-part"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "create_part.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/create_part.zip"
  source_code_hash = filebase64sha256("lambda/create_part.zip")

  environment {
    variables = {
      PARTS_TABLE_NEW = aws_dynamodb_table.parts_table_new.name
    }
  }

  tags = {
    Name = "Create Part Lambda"
  }
}

# --------------------
# Lambda Function: Update Part
# --------------------
resource "aws_lambda_function" "update_part" {
  function_name = "${var.project_name}-update-part"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "update_part.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/update_part.zip"
  source_code_hash = filebase64sha256("lambda/update_part.zip")

  environment {
    variables = {
      PARTS_TABLE_NEW = aws_dynamodb_table.parts_table_new.name
    }
  }

  tags = {
    Name = "Update Part Lambda"
  }
}

# --------------------
# Lambda Function: Delete Part
# --------------------
resource "aws_lambda_function" "delete_part" {
  function_name = "${var.project_name}-delete-part"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "delete_part.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/delete_part.zip"
  source_code_hash = filebase64sha256("lambda/delete_part.zip")

  environment {
    variables = {
      PARTS_TABLE_NEW = aws_dynamodb_table.parts_table_new.name
      BOXES_TABLE     = aws_dynamodb_table.boxes_table.name
    }
  }

  tags = {
    Name = "Delete Part Lambda"
  }
}

# --------------------
# Lambda Function: Create Box
# --------------------
resource "aws_lambda_function" "create_box" {
  function_name = "${var.project_name}-create-box"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "create_box.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/create_box.zip"
  source_code_hash = filebase64sha256("lambda/create_box.zip")

  environment {
    variables = {
      BOXES_TABLE   = aws_dynamodb_table.boxes_table.name
      PROJECT_TABLE = aws_dynamodb_table.project_table.name
    }
  }

  tags = {
    Name = "Create Box Lambda"
  }
}

# --------------------
# Lambda Function: Delete Box
# --------------------
resource "aws_lambda_function" "delete_box" {
  function_name = "${var.project_name}-delete-box"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "delete_box.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/delete_box.zip"
  source_code_hash = filebase64sha256("lambda/delete_box.zip")

  environment {
    variables = {
      BOXES_TABLE   = aws_dynamodb_table.boxes_table.name
      PROJECT_TABLE = aws_dynamodb_table.project_table.name
    }
  }

  tags = {
    Name = "Delete Box Lambda"
  }
}


# Terraform Template for OCR Pipeline with API Gateway Upload, Textract, Bedrock, and DynamoDB

# --------------------
# Providers & Variables
# --------------------
provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "ocr-label-app"
}

variable "jwt_secret" {
  description = "JWT secret for token signing"
  type        = string
  default     = "your-jwt-secret-change-this-in-production-make-it-long-and-random"
  sensitive   = true
}

# --------------------
# S3 Bucket for Image Uploads
# --------------------
resource "aws_s3_bucket" "ocr_images" {
  bucket = "${var.project_name}-images"
  force_destroy = true

  tags = {
    Name        = "OCR Image Uploads"
    Environment = "dev"
  }
}

# --------------------
# S3 Bucket for Processed Images
# --------------------
resource "aws_s3_bucket" "ocr_images_processed" {
  bucket = "${var.project_name}-images-processed"
  force_destroy = true

  tags = {
    Name        = "OCR Image Processing"
    Environment = "dev"
  }
}

# --------------------
# DynamoDB Table for Part Information (Legacy)
# --------------------
resource "aws_dynamodb_table" "parts_table" {
  name           = "${var.project_name}-parts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "internal_part_id"

  attribute {
    name = "internal_part_id"
    type = "S"
  }


  tags = {
    Name        = "Parts Table"
    Environment = "dev"
  }
}

# --------------------
# DynamoDB Table for Boxes
# --------------------
resource "aws_dynamodb_table" "boxes_table" {
  name           = "${var.project_name}-boxes"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "projectId"
  range_key      = "boxId"

  attribute {
    name = "boxId"
    type = "S"
  }
  attribute {
    name = "projectId"
    type = "S"
  }
  attribute {
    name = "parentBoxId"
    type = "S"
  }
  attribute {
    name = "dateCreated"
    type = "S"
  }
  attribute {
    name = "dateUpdated"
    type = "S"
  }

  global_secondary_index {
    name            = "boxId-index"
    hash_key        = "boxId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "projectId-dateCreated-index"
    hash_key        = "projectId"
    range_key       = "dateCreated"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "projectId-dateUpdated-index"
    hash_key        = "projectId"
    range_key       = "dateUpdated"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "parentBoxId-index"
    hash_key        = "parentBoxId"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Boxes Table"
    Environment = "dev"
  }
}

# --------------------
# DynamoDB Table for Parts (New) - boxId as partition key
# --------------------
resource "aws_dynamodb_table" "parts_table_new" {
  name           = "${var.project_name}-parts-new"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "boxId"
  range_key      = "partId"

  attribute {
    name = "boxId"
    type = "S"
  }
  attribute {
    name = "partId"
    type = "S"
  }
  attribute {
    name = "dateCreated"
    type = "S"
  }
  attribute {
    name = "dateUpdated"
    type = "S"
  }

  global_secondary_index {
    name            = "partId-index"
    hash_key        = "partId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "boxId-dateCreated-index"
    hash_key        = "boxId"
    range_key       = "dateCreated"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "boxId-dateUpdated-index"
    hash_key        = "boxId"
    range_key       = "dateUpdated"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Parts Table New BoxId Partition"
    Environment = "dev"
  }
}

# --------------------
# DynamoDB Table for Images
# --------------------
resource "aws_dynamodb_table" "images_table" {
  name           = "${var.project_name}-images"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "partId"
  range_key      = "imageId"

  attribute {
    name = "partId"
    type = "S"
  }
  attribute {
    name = "imageId"
    type = "S"
  }
  attribute {
    name = "dateCreated"
    type = "S"
  }

  global_secondary_index {
    name            = "imageId-index"
    hash_key        = "imageId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "dateCreated-index"
    hash_key        = "dateCreated"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Images Table"
    Environment = "dev"
  }
}

# --------------------
# IAM Roles & Policies
# --------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = ["${aws_s3_bucket.ocr_images.arn}/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = ["${aws_s3_bucket.ocr_images.arn}/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = ["${aws_s3_bucket.ocr_images_processed.arn}/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = ["${aws_s3_bucket.ocr_images_processed.arn}/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = ["${aws_s3_bucket.thumbnails.arn}/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["textract:DetectDocumentText"],
        Resource = ["*"]
      },
      {
        Effect   = "Allow",
        Action   = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ],
        Resource = ["*"]
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ],
        Resource = [aws_dynamodb_table.parts_table.arn]
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = [
          aws_dynamodb_table.user_table.arn,
          aws_dynamodb_table.project_table.arn,
          aws_dynamodb_table.boxes_table.arn,
          aws_dynamodb_table.parts_table_new.arn,
          aws_dynamodb_table.images_table.arn,
          "${aws_dynamodb_table.user_table.arn}/index/*",
          "${aws_dynamodb_table.project_table.arn}/index/*",
          "${aws_dynamodb_table.boxes_table.arn}/index/*",
          "${aws_dynamodb_table.parts_table_new.arn}/index/*",
          "${aws_dynamodb_table.images_table.arn}/index/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

# --------------------
# Lambda Function: Upload Handler (API Gateway Backend)
# --------------------
resource "aws_lambda_function" "upload_handler" {
  function_name = "${var.project_name}-upload-handler"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "upload_handler.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/upload_handler.zip"
  source_code_hash = filebase64sha256("lambda/upload_handler.zip")

  environment {
    variables = {
      UPLOAD_BUCKET = aws_s3_bucket.ocr_images.bucket
    }
  }

  tags = {
    Name = "Upload Lambda"
  }
}

# --------------------
# Lambda Function: OCR Processing Triggered by S3
# --------------------
resource "aws_lambda_function" "ocr_processor" {
  function_name = "${var.project_name}-ocr-processor"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "ocr_processor_copy.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/ocr_processor_copy.zip"
  source_code_hash = filebase64sha256("lambda/ocr_processor_copy.zip")

  environment {
    variables = {
      PARTS_TABLE = aws_dynamodb_table.parts_table.name,
      IMAGES_TABLE = aws_dynamodb_table.images_table.name,
      PROCESSED_BUCKET = aws_s3_bucket.ocr_images_processed.bucket,
      THUMBNAILS_BUCKET = aws_s3_bucket.thumbnails.bucket
    }
  }

  tags = {
    Name = "OCR Processor Lambda"
  }
}

# --------------------
# Lambda Function: Fetch Image by Image ID
# --------------------
resource "aws_lambda_function" "fetch_image" {
  function_name = "${var.project_name}-fetch-image"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "fetch_image.lambda_handler"
  timeout       = 30
  memory_size   = 128

  filename         = "lambda/fetch_image.zip"
  source_code_hash = filebase64sha256("lambda/fetch_image.zip")

  environment {
    variables = {
      IMAGES_TABLE = aws_dynamodb_table.images_table.name
    }
  }

  tags = {
    Name = "Fetch Image Lambda"
  }
}

# --------------------
# S3 Event Trigger for OCR Processor
# --------------------
resource "aws_s3_bucket_notification" "ocr_trigger" {
  bucket = aws_s3_bucket.ocr_images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.ocr_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ""
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke_ocr]
}

resource "aws_lambda_permission" "allow_s3_invoke_ocr" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ocr_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.ocr_images.arn
}

# --------------------
# API Gateway Setup
# --------------------
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "API Gateway for OCR pipeline"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent", "x-requested-with"]
    allow_methods     = ["GET", "HEAD", "OPTIONS", "POST", "PUT"]
    allow_origins     = ["*"]
    expose_headers    = ["x-amz-request-id", "x-amz-id-2"]
    max_age          = 86400
  }

  tags = {
    Name = "OCR API Gateway"
  }
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id = aws_apigatewayv2_api.api.id
  name   = "dev"
  auto_deploy = true

  tags = {
    Name = "API Stage"
  }
}

# --------------------
# API Gateway Upload Integration
# --------------------
resource "aws_apigatewayv2_integration" "upload_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.upload_handler.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_upload" {
  statement_id  = "AllowExecutionFromAPIGWUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --------------------
# API Gateway Integration and Routes for New Lambdas
# --------------------
resource "aws_apigatewayv2_integration" "create_user_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.create_user.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_user_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /user"
  target    = "integrations/${aws_apigatewayv2_integration.create_user_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_create_user" {
  statement_id  = "AllowExecutionFromAPIGWCreateUser"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "signin_user_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.signin_user.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "signin_user_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /user/signin"
  target    = "integrations/${aws_apigatewayv2_integration.signin_user_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_signin_user" {
  statement_id  = "AllowExecutionFromAPIGWSigninUser"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.signin_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "auth_middleware_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.auth_middleware.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_validate_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /auth/validate"
  target    = "integrations/${aws_apigatewayv2_integration.auth_middleware_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_auth_middleware" {
  statement_id  = "AllowExecutionFromAPIGWAuthMiddleware"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_middleware.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "create_project_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.create_project.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_project_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /project/create"
  target    = "integrations/${aws_apigatewayv2_integration.create_project_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_create_project" {
  statement_id  = "AllowExecutionFromAPIGWCreateProject"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_project.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "update_project_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.update_project.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "update_project_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /project/{project_id}"
  target    = "integrations/${aws_apigatewayv2_integration.update_project_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_update_project" {
  statement_id  = "AllowExecutionFromAPIGWUpdateProject"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_project.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "delete_project_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.delete_project.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "delete_project_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "DELETE /project/{project_id}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_project_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_delete_project" {
  statement_id  = "AllowExecutionFromAPIGWDeleteProject"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_project.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --------------------
# API Gateway Integration and Route for Endpoints Dashboard
# --------------------
resource "aws_apigatewayv2_integration" "endpoints_dashboard_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.endpoints_dashboard.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "endpoints_dashboard_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /endpoints"
  target    = "integrations/${aws_apigatewayv2_integration.endpoints_dashboard_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_endpoints_dashboard" {
  statement_id  = "AllowExecutionFromAPIGWEndpointsDashboard"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.endpoints_dashboard.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}


# --------------------
# API Gateway Integration and Route for Fetching Image by Image ID
# --------------------
resource "aws_apigatewayv2_integration" "fetch_image_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetch_image.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch_image_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /image/{imageId}"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_image_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_fetch_image" {
  statement_id  = "AllowExecutionFromAPIGWFetchImage"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_image.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}


# --------------------
# API Gateway Integrations and Routes for New Endpoints
# --------------------

# Fetch User Projects
resource "aws_apigatewayv2_integration" "fetch_user_projects_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetch_user_projects.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch_user_projects_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /user/projects"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_user_projects_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_fetch_user_projects" {
  statement_id  = "AllowExecutionFromAPIGWFetchUserProjects"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_user_projects.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Fetch User Projects (No Token)
resource "aws_apigatewayv2_integration" "fetch_user_projects_no_token_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetch_user_projects_no_token.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch_user_projects_no_token_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /user/{userId}/projects"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_user_projects_no_token_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_fetch_user_projects_no_token" {
  statement_id  = "AllowExecutionFromAPIGWFetchUserProjectsNoToken"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_user_projects_no_token.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Fetch Project Details
resource "aws_apigatewayv2_integration" "fetch_project_details_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetch_project_details.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch_project_details_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /project/{projectId}"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_project_details_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_fetch_project_details" {
  statement_id  = "AllowExecutionFromAPIGWFetchProjectDetails"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_project_details.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Fetch Box Details
resource "aws_apigatewayv2_integration" "fetch_box_details_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetch_box_details.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch_box_details_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /box/{boxId}"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_box_details_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_fetch_box_details" {
  statement_id  = "AllowExecutionFromAPIGWFetchBoxDetails"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_box_details.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Fetch Part Details
resource "aws_apigatewayv2_integration" "fetch_part_details_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetch_part_details.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch_part_details_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /part/{partId}"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_part_details_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_fetch_part_details" {
  statement_id  = "AllowExecutionFromAPIGWFetchPartDetails"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_part_details.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Create Part
resource "aws_apigatewayv2_integration" "create_part_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.create_part.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_part_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /part/create"
  target    = "integrations/${aws_apigatewayv2_integration.create_part_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_create_part" {
  statement_id  = "AllowExecutionFromAPIGWCreatePart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_part.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Update Part
resource "aws_apigatewayv2_integration" "update_part_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.update_part.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "update_part_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /part/{partId}"
  target    = "integrations/${aws_apigatewayv2_integration.update_part_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_update_part" {
  statement_id  = "AllowExecutionFromAPIGWUpdatePart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_part.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Delete Part
resource "aws_apigatewayv2_integration" "delete_part_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.delete_part.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "delete_part_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "DELETE /part/{partId}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_part_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_delete_part" {
  statement_id  = "AllowExecutionFromAPIGWDeletePart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_part.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Create Box
resource "aws_apigatewayv2_integration" "create_box_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.create_box.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_box_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /box/create"
  target    = "integrations/${aws_apigatewayv2_integration.create_box_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_create_box" {
  statement_id  = "AllowExecutionFromAPIGWCreateBox"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_box.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Delete Box
resource "aws_apigatewayv2_integration" "delete_box_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.delete_box.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "delete_box_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "DELETE /box/{boxId}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_box_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_delete_box" {
  statement_id  = "AllowExecutionFromAPIGWDeleteBox"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_box.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --------------------
# S3 Bucket CORS Configuration for Direct Upload
# --------------------
resource "aws_s3_bucket_cors_configuration" "ocr_images_cors" {
  bucket = aws_s3_bucket.ocr_images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# --------------------
# S3 Bucket Public Access Block Configuration
# --------------------
resource "aws_s3_bucket_public_access_block" "ocr_images_public_access" {
  bucket = aws_s3_bucket.ocr_images.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# --------------------
# S3 Bucket Policy for Public Read Access
# --------------------
resource "aws_s3_bucket_policy" "ocr_images_public_read" {
  bucket = aws_s3_bucket.ocr_images.id
  depends_on = [aws_s3_bucket_public_access_block.ocr_images_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.ocr_images.arn}/uploads/*"
      }
    ]
  })
}

# --------------------
# Lambda Function: Presigned Upload Handler
# --------------------
resource "aws_lambda_function" "presigned_upload_handler" {
  function_name = "${var.project_name}-presigned-upload-handler"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "presigned_upload_handler.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/presigned_upload_handler.zip"
  source_code_hash = filebase64sha256("lambda/presigned_upload_handler.zip")

  environment {
    variables = {
      UPLOAD_BUCKET = aws_s3_bucket.ocr_images.bucket,
      IMAGES_TABLE = aws_dynamodb_table.images_table.name
    }
  }

  tags = {
    Name = "Presigned Upload Handler Lambda"
  }
}

# --------------------
# Lambda Function: Upload Status Handler
# --------------------
resource "aws_lambda_function" "upload_status_handler" {
  function_name = "${var.project_name}-upload-status-handler"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "upload_status_handler.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/upload_status_handler.zip"
  source_code_hash = filebase64sha256("lambda/upload_status_handler.zip")

  environment {
    variables = {
      UPLOAD_BUCKET = aws_s3_bucket.ocr_images.bucket
    }
  }

  tags = {
    Name = "Upload Status Handler Lambda"
  }
}

# --------------------
# API Gateway Integration for Presigned Upload Handler
# --------------------
resource "aws_apigatewayv2_integration" "presigned_upload_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.presigned_upload_handler.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "presigned_upload_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /get-presigned-url"
  target    = "integrations/${aws_apigatewayv2_integration.presigned_upload_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_presigned_upload" {
  statement_id  = "AllowExecutionFromAPIGWPresignedUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_upload_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --------------------
# API Gateway Integration for Upload Status Handler
# --------------------
resource "aws_apigatewayv2_integration" "upload_status_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.upload_status_handler.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload_status_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /upload-status"
  target    = "integrations/${aws_apigatewayv2_integration.upload_status_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_upload_status" {
  statement_id  = "AllowExecutionFromAPIGWUploadStatus"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_status_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --------------------
# CloudFront Distribution for Images
# --------------------

# Origin Access Control for secure S3 access
resource "aws_cloudfront_origin_access_control" "images_oac" {
  name                              = "${var.project_name}-images-oac"
  description                       = "OAC for images S3 buckets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "images_cdn" {
  comment             = "${var.project_name} Images CDN"
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"  # Use only North America and Europe edge locations

  # Origin for original images bucket
  origin {
    domain_name              = aws_s3_bucket.ocr_images.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.images_oac.id
    origin_id                = "S3-${aws_s3_bucket.ocr_images.bucket}"
  }

  # Origin for processed images bucket
  origin {
    domain_name              = aws_s3_bucket.ocr_images_processed.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.images_oac.id
    origin_id                = "S3-${aws_s3_bucket.ocr_images_processed.bucket}"
  }

  # Origin for thumbnails bucket
  origin {
    domain_name              = aws_s3_bucket.thumbnails.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.images_oac.id
    origin_id                = "S3-${aws_s3_bucket.thumbnails.bucket}"
  }

  # Default cache behavior (for uploads path)
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.ocr_images.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      cookies {
        forward = "none"
      }
    }

    # Cache settings optimized for images
    min_ttl                = 0
    default_ttl            = 86400    # 1 day
    max_ttl                = 31536000 # 1 year
  }

  # Cache behavior for processed images
  ordered_cache_behavior {
    path_pattern           = "/processed/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.ocr_images_processed.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 604800   # 7 days (processed images change less frequently)
    max_ttl                = 31536000 # 1 year
  }

  # Cache behavior for thumbnails
  ordered_cache_behavior {
    path_pattern           = "/thumbnails/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.thumbnails.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 2592000  # 30 days (thumbnails are static)
    max_ttl                = 31536000 # 1 year
  }

  # Geographic restrictions (optional - remove if you need global access)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Custom error pages
  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  tags = {
    Name        = "${var.project_name} Images CDN"
    Environment = "dev"
  }
}

# Update S3 bucket policies to work with CloudFront OAC
resource "aws_s3_bucket_policy" "ocr_images_cloudfront" {
  bucket = aws_s3_bucket.ocr_images.id
  depends_on = [aws_s3_bucket_public_access_block.ocr_images_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.ocr_images.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.images_cdn.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "ocr_images_processed_cloudfront" {
  bucket = aws_s3_bucket.ocr_images_processed.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.ocr_images_processed.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.images_cdn.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "thumbnails_cloudfront" {
  bucket = aws_s3_bucket.thumbnails.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.thumbnails.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.images_cdn.arn
          }
        }
      }
    ]
  })
}

# Remove the old public read policy since we're using CloudFront
# Comment out or remove the aws_s3_bucket_policy.ocr_images_public_read resource

# --------------------
# Outputs
# --------------------
output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
}

output "endpoints_dashboard_url" {
  description = "Endpoints Dashboard URL"
  value       = "${aws_apigatewayv2_stage.api_stage.invoke_url}/endpoints"
}

# --------------------
# DynamoDB Table Name Outputs
# --------------------
output "boxes_table_name" {
  description = "Name of the boxes DynamoDB table"
  value       = aws_dynamodb_table.boxes_table.name
}

output "parts_table_new_name" {
  description = "Name of the parts (new) DynamoDB table"
  value       = aws_dynamodb_table.parts_table_new.name
}

output "images_table_name" {
  description = "Name of the images DynamoDB table"
  value       = aws_dynamodb_table.images_table.name
}

output "user_table_name" {
  description = "Name of the user DynamoDB table"
  value       = aws_dynamodb_table.user_table.name
}

output "project_table_name" {
  description = "Name of the project DynamoDB table"
  value       = aws_dynamodb_table.project_table.name
}

output "presigned_upload_url" {
  description = "Presigned Upload Handler API URL"
  value       = "${aws_apigatewayv2_stage.api_stage.invoke_url}/get-presigned-url"
}

output "upload_status_url" {
  description = "Upload Status Handler API URL"
  value       = "${aws_apigatewayv2_stage.api_stage.invoke_url}/upload-status"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for uploads"
  value       = aws_s3_bucket.ocr_images.bucket
}

output "thumbnails_bucket_name" {
  description = "Name of the S3 bucket for thumbnails"
  value       = aws_s3_bucket.thumbnails.bucket
}

output "signin_url" {
  description = "User Sign-in API URL"
  value       = "${aws_apigatewayv2_stage.api_stage.invoke_url}/user/signin"
}

output "fetch_image_url" {
  description = "Fetch Image API URL (use {imageId} as placeholder)"
  value       = "${aws_apigatewayv2_stage.api_stage.invoke_url}/image/{imageId}"
}

# --------------------
# CloudFront CDN Outputs
# --------------------
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for images"
  value       = aws_cloudfront_distribution.images_cdn.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name for images"
  value       = aws_cloudfront_distribution.images_cdn.domain_name
}

output "cloudfront_url" {
  description = "CloudFront URL for images (HTTPS)"
  value       = "https://${aws_cloudfront_distribution.images_cdn.domain_name}"
}

output "image_urls_info" {
  description = "Information about accessing images through CloudFront"
  value = {
    original_images = "https://${aws_cloudfront_distribution.images_cdn.domain_name}/uploads/[filename]"
    processed_images = "https://${aws_cloudfront_distribution.images_cdn.domain_name}/processed/[filename]"
    thumbnails = "https://${aws_cloudfront_distribution.images_cdn.domain_name}/thumbnails/[filename]"
    note = "Replace [filename] with actual image filename. CloudFront will serve from appropriate S3 bucket based on path."
  }
}

