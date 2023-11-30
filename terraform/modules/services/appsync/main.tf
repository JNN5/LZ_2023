resource "aws_appsync_graphql_api" "graphql_api" {
  name                = var.appsync.name
  authentication_type = var.appsync.authentication_type
  schema              = file(var.appsync.schema_file_name)

  dynamic "log_config" {
    for_each = var.appsync.logging_enabled ? [1] : []

    content {
      cloudwatch_logs_role_arn = var.appsync_cloudwatch_role_arn
      field_log_level          = "ERROR"
    }
  }

  dynamic "user_pool_config" {
    for_each = length(keys(var.appsync.user_pool_config)) == 0 ? [] : [1]

    content {
      default_action      = var.appsync.user_pool_config["default_action"]
      user_pool_id        = var.user_pool_ids[var.appsync.user_pool_config["user_pool_name"]]
      app_id_client_regex = lookup(var.appsync.user_pool_config, "app_id_client_regex", null)
      aws_region          = lookup(var.appsync.user_pool_config, "aws_region", "ap-southeast-1")
    }
  }

  dynamic "additional_authentication_provider" {
    for_each = var.appsync.additional_authentication_provider

    content {
      authentication_type = additional_authentication_provider.value.authentication_type
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.appsync.name
    },
  )
}

# API KEY
resource "aws_appsync_api_key" "api_key" {
  count = var.appsync.authentication_type == "API_KEY" ? 1 : 0

  api_id      = aws_appsync_graphql_api.graphql_api.id
  description = var.appsync.name
}

# Datasource
resource "aws_appsync_datasource" "datasource" {
  for_each = var.appsync_datasources

  api_id           = aws_appsync_graphql_api.graphql_api.id
  name             = each.key
  type             = each.value.type
  service_role_arn = var.appsync_service_role_arn

  dynamic "http_config" {
    for_each = each.value.type == "HTTP" ? [true] : []

    content {
      endpoint = each.value.endpoint
    }
  }

  dynamic "lambda_config" {
    for_each = each.value.type == "AWS_LAMBDA" ? [true] : []

    content {
      function_arn = var.lambda_arns[each.key]
    }
  }

  dynamic "dynamodb_config" {
    for_each = each.value.type == "AMAZON_DYNAMODB" ? [true] : []

    content {
      table_name             = each.value.table_name
      region                 = lookup(each.value, "region", "ap-southeast-1")
      use_caller_credentials = lookup(each.value, "use_caller_credentials", null)
    }
  }

  dynamic "elasticsearch_config" {
    for_each = each.value.type == "AMAZON_ELASTICSEARCH" ? [true] : []

    content {
      endpoint = each.value.endpoint
      region   = lookup(each.value, "region", "ap-southeast-1")
    }
  }
}

# Resolvers
resource "aws_appsync_resolver" "resolvers" {
  for_each = { for resolver in var.appsync_resolvers : "${resolver.type}.${resolver.field}" => resolver }

  api_id = aws_appsync_graphql_api.graphql_api.id
  type   = each.value.type
  field  = each.value.field
  kind   = lookup(each.value, "kind", null)
  code   = lookup(each.value, "code_path", null) != null ? file(each.value.code_path) : null

  request_template  = lookup(each.value, "runtime", null) == null ? lookup(each.value, "request_template", tobool(lookup(each.value, "direct_lambda", false)) ? var.direct_lambda_request_template : "{}") : null
  response_template = lookup(each.value, "runtime", null) == null ? lookup(each.value, "response_template", tobool(lookup(each.value, "direct_lambda", false)) ? var.direct_lambda_response_template : "{}") : null

  data_source = lookup(each.value, "runtime", null) == null && lookup(each.value, "data_source", null) != null ? aws_appsync_datasource.datasource[each.value.data_source].name : lookup(each.value, "data_source_arn", null)
  
  dynamic "runtime" {
    for_each = lookup(each.value, "runtime", null) != null ? [true] : []

    content {
      name            = each.value.runtime
      runtime_version = each.value.runtime_version
    }
  }

  dynamic "pipeline_config" {
    for_each = lookup(each.value, "functions", null) != null ? [true] : []

    content {
      functions = [for k in each.value.functions :
      contains(keys(aws_appsync_function.appsync_function), k) ? aws_appsync_function.appsync_function[k].function_id : k]
    }
  }

    dynamic "caching_config" {
      for_each = lookup(each.value, "caching_keys", null) != null ? [true] : []

      content {
        caching_keys = each.value.caching_keys
        ttl          = lookup(each.value, "caching_ttl", var.resolver_caching_ttl)
      }
    }
}

resource "aws_appsync_function" "appsync_function" {
  for_each = var.appsync_functions

  api_id      = aws_appsync_graphql_api.graphql_api.id
  data_source = each.value.datasource
  name        = each.key
  code        = file(each.value.code_path)

  runtime {
    name            = each.value.runtime
    runtime_version = each.value.runtime_version
  }
}
