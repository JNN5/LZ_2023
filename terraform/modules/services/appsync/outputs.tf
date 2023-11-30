output "appsync_url" {
  description = "Appsync URL"
  value = aws_appsync_graphql_api.graphql_api.uris["GRAPHQL"]
}