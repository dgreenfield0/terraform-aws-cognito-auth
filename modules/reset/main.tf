# Copyright (c) 2018 Martin Donath <martin.donath@squidfunk.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

# -----------------------------------------------------------------------------
# Data: General
# -----------------------------------------------------------------------------

# data.aws_caller_identity._
data "aws_caller_identity" "_" {}

# -----------------------------------------------------------------------------
# Resources: API Gateway: POST /reset
# -----------------------------------------------------------------------------

# aws_api_gateway_resource._
resource "aws_api_gateway_resource" "_" {
  rest_api_id = "${var.api_id}"
  parent_id   = "${var.api_resource_id}"
  path_part   = "reset"
}

# aws_api_gateway_method._
resource "aws_api_gateway_method" "_" {
  rest_api_id   = "${var.api_id}"
  resource_id   = "${aws_api_gateway_resource._.id}"
  http_method   = "POST"
  authorization = "NONE"
}

# aws_api_gateway_integration._
resource "aws_api_gateway_integration" "_" {
  rest_api_id = "${var.api_id}"
  resource_id = "${aws_api_gateway_resource._.id}"
  http_method = "${aws_api_gateway_method._.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = "arn:aws:apigateway:${
      var.region
    }:lambda:path/2015-03-31/functions/${
      aws_lambda_function._.arn
    }/invocations"
}

# -----------------------------------------------------------------------------
# Resources: API Gateway: POST /reset/{code}
# -----------------------------------------------------------------------------

# aws_api_gateway_resource.verify
resource "aws_api_gateway_resource" "verify" {
  rest_api_id = "${var.api_id}"
  parent_id   = "${aws_api_gateway_resource._.id}"
  path_part   = "{code}"
}

# aws_api_gateway_method.verify
resource "aws_api_gateway_method" "verify" {
  rest_api_id   = "${var.api_id}"
  resource_id   = "${aws_api_gateway_resource.verify.id}"
  http_method   = "POST"
  authorization = "NONE"
}

# aws_api_gateway_integration.verify
resource "aws_api_gateway_integration" "verify" {
  rest_api_id = "${var.api_id}"
  resource_id = "${aws_api_gateway_resource.verify.id}"
  http_method = "${aws_api_gateway_method.verify.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = "arn:aws:apigateway:${
      var.region
    }:lambda:path/2015-03-31/functions/${
      aws_lambda_function.verify.arn
    }/invocations"
}

# -----------------------------------------------------------------------------
# Resources: Lambda
# -----------------------------------------------------------------------------

# aws_lambda_function._
resource "aws_lambda_function" "_" {
  function_name = "${var.namespace}-reset"
  role          = "${var.lambda_role_arn}"
  runtime       = "nodejs8.10"
  filename      = "${var.lambda_filename}"
  handler       = "handlers/reset/index.post"
  timeout       = 10

  source_code_hash = "${
    base64sha256(file("${var.lambda_filename}"))
  }"

  environment {
    variables = {
      COGNITO_USER_POOL        = "${var.cognito_user_pool}"
      COGNITO_USER_POOL_CLIENT = "${var.cognito_user_pool_client}"
      DYNAMODB_TABLE           = "${var.dynamodb_table}"
    }
  }
}

# aws_lambda_permission._
resource "aws_lambda_permission" "_" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function._.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${
      var.region
    }:${
      data.aws_caller_identity._.account_id
    }:${
      var.api_id
    }/*/${
      aws_api_gateway_method._.http_method
    }${
      aws_api_gateway_resource._.path
    }"
}

# -----------------------------------------------------------------------------

# aws_lambda_function.verify
resource "aws_lambda_function" "verify" {
  function_name = "${var.namespace}-reset-verify"
  role          = "${var.lambda_role_arn}"
  runtime       = "nodejs8.10"
  filename      = "${var.lambda_filename}"
  handler       = "handlers/reset/verify.post"
  timeout       = 10

  source_code_hash = "${
    base64sha256(file("${var.lambda_filename}"))
  }"

  environment {
    variables = {
      COGNITO_USER_POOL        = "${var.cognito_user_pool}"
      COGNITO_USER_POOL_CLIENT = "${var.cognito_user_pool_client}"
      DYNAMODB_TABLE           = "${var.dynamodb_table}"
    }
  }
}

# aws_lambda_permission.verify
resource "aws_lambda_permission" "verify" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.verify.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${
      var.region
    }:${
      data.aws_caller_identity._.account_id
    }:${
      var.api_id
    }/*/${
      aws_api_gateway_method.verify.http_method
    }${
      aws_api_gateway_resource.verify.path
    }"
}
