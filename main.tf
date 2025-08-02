# Terraform Configuration for User/Event/Team Management System

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
  default = "flag-nation-test"
}

variable "jwt_secret" {
  description = "JWT secret for token signing"
  type        = string
  default     = "your-jwt-secret-change-this-in-production-make-it-long-and-random"
  sensitive   = true
}

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
  attribute {
    name = "first_name"
    type = "S"
  }
  attribute {
    name = "last_name"
    type = "S"
  }
  attribute {
    name = "email"
    type = "S"
  }
  attribute {
    name = "phone_number"
    type = "S"
  }

  global_secondary_index {
    name            = "username-index"
    hash_key        = "username"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "first_name-index"
    hash_key        = "first_name"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "last_name-index"
    hash_key        = "last_name"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "phone_number-index"
    hash_key        = "phone_number"
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
resource "aws_dynamodb_table" "events_table" {
  name           = "${var.project_name}-events"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "name"
    type = "S"
  }
  attribute {
    name = "status"
    type = "S"
  }
  attribute {
    name = "date_start"
    type = "S"
  }
  attribute {
    name = "date_end"
    type = "S"
  }
  attribute {
    name = "parent_event_id"
    type = "S"
  }

  global_secondary_index {
    name            = "name-index"
    hash_key        = "name"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "date_start-index"
    hash_key        = "date_start"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "date_end-index"
    hash_key        = "date_end"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "parent_event_id-index"
    hash_key        = "parent_event_id"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Events Table"
    Environment = "dev"
  }
}

# --------------------
# DynamoDB Table for Teams
# --------------------
resource "aws_dynamodb_table" "teams_table" {
  name           = "${var.project_name}-teams"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "name"
    type = "S"
  }
  attribute {
    name = "team_captain_id"
    type = "S"
  }
  attribute {
    name = "parent_team_id"
    type = "S"
  }

  global_secondary_index {
    name            = "name-index"
    hash_key        = "name"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "team_captain_id-index"
    hash_key        = "team_captain_id"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "parent_team_id-index"
    hash_key        = "parent_team_id"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Teams Table"
    Environment = "dev"
  }
}

# --------------------
# DynamoDB Table for Event Registrations
# --------------------
resource "aws_dynamodb_table" "event_registrations_table" {
  name           = "${var.project_name}-event-registrations"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "event_id"
  range_key      = "team_id"

  attribute {
    name = "event_id"
    type = "S"
  }
  attribute {
    name = "team_id"
    type = "S"
  }
  attribute {
    name = "event_name"
    type = "S"
  }
  attribute {
    name = "team_name"
    type = "S"
  }

  global_secondary_index {
    name            = "team_id-index"
    hash_key        = "team_id"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "event_name-index"
    hash_key        = "event_name"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "team_name-index"
    hash_key        = "team_name"
    projection_type = "ALL"
  }

  tags = {
    Name        = "Event Registrations Table"
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
          aws_dynamodb_table.events_table.arn,
          aws_dynamodb_table.teams_table.arn,
          aws_dynamodb_table.event_registrations_table.arn,
          "${aws_dynamodb_table.user_table.arn}/index/*",
          "${aws_dynamodb_table.events_table.arn}/index/*",
          "${aws_dynamodb_table.teams_table.arn}/index/*",
          "${aws_dynamodb_table.event_registrations_table.arn}/index/*"
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
# Lambda Functions for User Management
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
# Lambda Functions for Event Management
# --------------------
resource "aws_lambda_function" "create_event" {
  function_name = "${var.project_name}-create-event"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "create_event.lambda_handler"
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

resource "aws_lambda_function" "update_event" {
  function_name = "${var.project_name}-update-event"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "update_event.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/update_event.zip"
  source_code_hash = filebase64sha256("lambda/update_event.zip")

  environment {
    variables = {
      EVENTS_TABLE = aws_dynamodb_table.events_table.name
    }
  }

  tags = {
    Name = "Update Event Lambda"
  }
}

resource "aws_lambda_function" "delete_event" {
  function_name = "${var.project_name}-delete-event"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "delete_event.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/delete_event.zip"
  source_code_hash = filebase64sha256("lambda/delete_event.zip")

  environment {
    variables = {
      EVENTS_TABLE = aws_dynamodb_table.events_table.name
    }
  }

  tags = {
    Name = "Delete Event Lambda"
  }
}

resource "aws_lambda_function" "fetch_events" {
  function_name = "${var.project_name}-fetch-events"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "fetch_events.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/fetch_events.zip"
  source_code_hash = filebase64sha256("lambda/fetch_events.zip")

  environment {
    variables = {
      EVENTS_TABLE = aws_dynamodb_table.events_table.name
    }
  }

  tags = {
    Name = "Fetch Events Lambda"
  }
}

# --------------------
# Lambda Functions for Team Management
# --------------------
resource "aws_lambda_function" "create_team" {
  function_name = "${var.project_name}-create-team"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "create_team.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/create_team.zip"
  source_code_hash = filebase64sha256("lambda/create_team.zip")

  environment {
    variables = {
      TEAMS_TABLE = aws_dynamodb_table.teams_table.name
    }
  }

  tags = {
    Name = "Create Team Lambda"
  }
}

resource "aws_lambda_function" "update_team" {
  function_name = "${var.project_name}-update-team"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "update_team.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/update_team.zip"
  source_code_hash = filebase64sha256("lambda/update_team.zip")

  environment {
    variables = {
      TEAMS_TABLE = aws_dynamodb_table.teams_table.name
    }
  }

  tags = {
    Name = "Update Team Lambda"
  }
}

resource "aws_lambda_function" "delete_team" {
  function_name = "${var.project_name}-delete-team"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "delete_team.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/delete_team.zip"
  source_code_hash = filebase64sha256("lambda/delete_team.zip")

  environment {
    variables = {
      TEAMS_TABLE = aws_dynamodb_table.teams_table.name
    }
  }

  tags = {
    Name = "Delete Team Lambda"
  }
}

resource "aws_lambda_function" "fetch_teams" {
  function_name = "${var.project_name}-fetch-teams"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "fetch_teams.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/fetch_teams.zip"
  source_code_hash = filebase64sha256("lambda/fetch_teams.zip")

  environment {
    variables = {
      TEAMS_TABLE = aws_dynamodb_table.teams_table.name
    }
  }

  tags = {
    Name = "Fetch Teams Lambda"
  }
}

# --------------------
# Lambda Functions for Event Registration Management
# --------------------
resource "aws_lambda_function" "create_event_registration" {
  function_name = "${var.project_name}-create-event-registration"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "create_event_registration.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/create_event_registration.zip"
  source_code_hash = filebase64sha256("lambda/create_event_registration.zip")

  environment {
    variables = {
      EVENT_REGISTRATIONS_TABLE = aws_dynamodb_table.event_registrations_table.name
    }
  }

  tags = {
    Name = "Create Event Registration Lambda"
  }
}

resource "aws_lambda_function" "delete_event_registration" {
  function_name = "${var.project_name}-delete-event-registration"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "delete_event_registration.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/delete_event_registration.zip"
  source_code_hash = filebase64sha256("lambda/delete_event_registration.zip")

  environment {
    variables = {
      EVENT_REGISTRATIONS_TABLE = aws_dynamodb_table.event_registrations_table.name
    }
  }

  tags = {
    Name = "Delete Event Registration Lambda"
  }
}

resource "aws_lambda_function" "fetch_event_registrations" {
  function_name = "${var.project_name}-fetch-event-registrations"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "fetch_event_registrations.lambda_handler"
  timeout       = 30
  memory_size   = 512

  filename         = "lambda/fetch_event_registrations.zip"
  source_code_hash = filebase64sha256("lambda/fetch_event_registrations.zip")

  environment {
    variables = {
      EVENT_REGISTRATIONS_TABLE = aws_dynamodb_table.event_registrations_table.name
    }
  }

  tags = {
    Name = "Fetch Event Registrations Lambda"
  }
}

# --------------------
# API Gateway Setup
# --------------------
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "API Gateway for User/Event/Team Management"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent", "x-requested-with"]
    allow_methods     = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "DELETE"]
    allow_origins     = ["*"]
    expose_headers    = ["x-amz-request-id", "x-amz-id-2"]
    max_age          = 86400
  }

  tags = {
    Name = "User/Event/Team API Gateway"
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
# API Gateway Integrations and Routes for User Management
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

# --------------------
# API Gateway Integrations and Routes for Event Management
# --------------------
resource "aws_apigatewayv2_integration" "create_event_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.create_event.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_event_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /event"
  target    = "integrations/${aws_apigatewayv2_integration.create_event_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_create_event" {
  statement_id  = "AllowExecutionFromAPIGWCreateEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_event.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "update_event_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.update_event.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "update_event_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /event/{event_id}"
  target    = "integrations/${aws_apigatewayv2_integration.update_event_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_update_event" {
  statement_id  = "AllowExecutionFromAPIGWUpdateEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_event.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "delete_event_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.delete_event.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "delete_event_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "DELETE /event/{event_id}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_event_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_delete_event" {
  statement_id  = "AllowExecutionFromAPIGWDeleteEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_event.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "fetch_events_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetch_events.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch_events_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /events"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_events_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_fetch_events" {
  statement_id  = "AllowExecutionFromAPIGWFetchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_events.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --------------------
# API Gateway Integrations and Routes for Team Management
# --------------------
resource "aws_apigatewayv2_integration" "create_team_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.create_team.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_team_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /team"
  target    = "integrations/${aws_apigatewayv2_integration.create_team_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_create_team" {
  statement_id  = "AllowExecutionFromAPIGWCreateTeam"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_team.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "update_team_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.update_team.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "update_team_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /team/{team_id}"
  target    = "integrations/${aws_apigatewayv2_integration.update_team_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_update_team" {
  statement_id  = "AllowExecutionFromAPIGWUpdateTeam"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_team.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "delete_team_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.delete_team.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "delete_team_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "DELETE /team/{team_id}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_team_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_delete_team" {
  statement_id  = "AllowExecutionFromAPIGWDeleteTeam"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_team.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "fetch_teams_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetch_teams.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch_teams_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /teams"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_teams_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_fetch_teams" {
  statement_id  = "AllowExecutionFromAPIGWFetchTeams"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_teams.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --------------------
# API Gateway Integrations and Routes for Event Registration Management
# --------------------
resource "aws_apigatewayv2_integration" "create_event_registration_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.create_event_registration.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_event_registration_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /event-registration"
  target    = "integrations/${aws_apigatewayv2_integration.create_event_registration_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_create_event_registration" {
  statement_id  = "AllowExecutionFromAPIGWCreateEventRegistration"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_event_registration.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "delete_event_registration_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.delete_event_registration.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "delete_event_registration_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "DELETE /event-registration/{event_id}/{team_id}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_event_registration_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_delete_event_registration" {
  statement_id  = "AllowExecutionFromAPIGWDeleteEventRegistration"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_event_registration.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "fetch_event_registrations_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetch_event_registrations.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "fetch_event_registrations_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /event-registrations"
  target    = "integrations/${aws_apigatewayv2_integration.fetch_event_registrations_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw_fetch_event_registrations" {
  statement_id  = "AllowExecutionFromAPIGWFetchEventRegistrations"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_event_registrations.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# --------------------
# Outputs
# --------------------
output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
}

output "user_table_name" {
  description = "Name of the user DynamoDB table"
  value       = aws_dynamodb_table.user_table.name
}

output "events_table_name" {
  description = "Name of the events DynamoDB table"
  value       = aws_dynamodb_table.events_table.name
}

output "teams_table_name" {
  description = "Name of the teams DynamoDB table"
  value       = aws_dynamodb_table.teams_table.name
}

output "event_registrations_table_name" {
  description = "Name of the event registrations DynamoDB table"
  value       = aws_dynamodb_table.event_registrations_table.name
}

output "api_endpoints" {
  description = "Available API endpoints"
  value = {
    user_endpoints = {
      create_user = "${aws_apigatewayv2_stage.api_stage.invoke_url}/user"
      signin_user = "${aws_apigatewayv2_stage.api_stage.invoke_url}/user/signin"
    }
    event_endpoints = {
      create_event  = "${aws_apigatewayv2_stage.api_stage.invoke_url}/event"
      update_event  = "${aws_apigatewayv2_stage.api_stage.invoke_url}/event/{event_id}"
      delete_event  = "${aws_apigatewayv2_stage.api_stage.invoke_url}/event/{event_id}"
      fetch_events  = "${aws_apigatewayv2_stage.api_stage.invoke_url}/events"
    }
    team_endpoints = {
      create_team   = "${aws_apigatewayv2_stage.api_stage.invoke_url}/team"
      update_team   = "${aws_apigatewayv2_stage.api_stage.invoke_url}/team/{team_id}"
      delete_team   = "${aws_apigatewayv2_stage.api_stage.invoke_url}/team/{team_id}"
      fetch_teams   = "${aws_apigatewayv2_stage.api_stage.invoke_url}/teams"
    }
    event_registration_endpoints = {
      create_registration = "${aws_apigatewayv2_stage.api_stage.invoke_url}/event-registration"
      delete_registration = "${aws_apigatewayv2_stage.api_stage.invoke_url}/event-registration/{event_id}/{team_id}"
      fetch_registrations = "${aws_apigatewayv2_stage.api_stage.invoke_url}/event-registrations"
    }
  }
}
