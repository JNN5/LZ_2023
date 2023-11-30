resource "aws_appconfig_application" "app" {
  name        = var.tags["Project"]
  description = "DIVA Feature Store Application"

  tags = var.tags
}

resource "aws_appconfig_environment" "env" {
  name           = "FeatureFlags"
  description    = "DIVA Feature Store Environment"
  application_id = aws_appconfig_application.app.id

#   monitor {
#     alarm_arn      = aws_cloudwatch_metric_alarm.example.arn
#     alarm_role_arn = aws_iam_role.example.arn
#   }

  tags = var.tags
}

resource "aws_appconfig_configuration_profile" "config_profile" {
    for_each       = var.feature_flags
    application_id = aws_appconfig_application.app.id
    description    = "${each.key}: ${each.value.name} Configuration Profile"
    name           = "${each.key}: ${each.value.name}"
    location_uri   = "hosted"

    validator {
    content = jsonencode({
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "$id$",
        "description": "A simple toggle",
        "type": "object",
        "properties": {
            "enabled": {
                "description": "Specifies whether the feature is active",
                "type": "object",
                "properties": {
                    "default": {
                        "type": "boolean"
                    }
                }
            }
        },
        "required": [ "enabled" ]
        })
    type    = "JSON_SCHEMA"
    }

    tags = var.tags
}

resource "aws_appconfig_hosted_configuration_version" "flag_version_default" {
    for_each                 = var.feature_flags
    application_id           = aws_appconfig_application.app.id
    configuration_profile_id = aws_appconfig_configuration_profile.config_profile[each.key].configuration_profile_id
    description              = "${each.key}: ${each.value.name} Default Configuration Version"
    content_type             = "application/json"

    content = jsonencode({
        "enabled": {
            "default": each.value.enabled
            }
    })
    
}

resource "aws_appconfig_hosted_configuration_version" "flag_version_inverse" {
    for_each                 = var.feature_flags
    application_id           = aws_appconfig_application.app.id
    configuration_profile_id = aws_appconfig_configuration_profile.config_profile[each.key].configuration_profile_id
    description              = "${each.key}: ${each.value.name} Inverse Configuration Version"
    content_type             = "application/json"

    content = jsonencode({
        "enabled": {
            "default": each.value.enabled == false ? true : false
        }
    })

    depends_on = [
      aws_appconfig_hosted_configuration_version.flag_version_default
    ]
    
}

resource "aws_appconfig_deployment" "deployment" {
    for_each                 = var.feature_flags
    application_id           = aws_appconfig_application.app.id
    configuration_profile_id = aws_appconfig_configuration_profile.config_profile[each.key].configuration_profile_id
    configuration_version    = aws_appconfig_hosted_configuration_version.flag_version_default[each.key].version_number
    deployment_strategy_id   = "AppConfig.AllAtOnce"
    description              = "DIVA feature flag deployment of the default version"
    environment_id           = aws_appconfig_environment.env.environment_id

    tags = var.tags
}