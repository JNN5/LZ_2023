import os
from typing import Callable
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.logging.correlation_paths import API_GATEWAY_REST
from datetime import datetime
from shared.git_repo import GitRepo
from shared.service_now_dto import ServiceNowDto
from shared.request_validation import parse_event
from shared.api_response_handler import as_api
from shared.tfvars_templates.lambda_template import LambdaTemplate
from shared.tfvars_templates.api_gw_template import ApiGatewayTemplate
from shared.tfvars_templates.dynamodb_template import DynamoDbTemplate
from functools import reduce


CORS = "*"

REPO = os.environ.get("REPO", "https://git-codecommit.ap-southeast-1.amazonaws.com/v1/repos/CAG-CodeRepo")
LOCAL_DIR = os.environ.get("LOCAL_DIR", "repo_clone")
TFVARS_FILE = os.environ.get("TFVARS_FILE", "launchpad.tfvars.json")

log = Logger()
tracer = Tracer()


@tracer.capture_lambda_handler
@log.inject_lambda_context(correlation_id_path=API_GATEWAY_REST, log_event=True)
@as_api(CORS)
def handler(event, context):
    request: ServiceNowDto = parse_event(event, ServiceNowDto)
    repo = GitRepo(REPO,LOCAL_DIR)

    new_lambdas = {}
    new_api_resources = {}
    new_ddb_tables = []

    for req_data in request.request_data:
        new_lambdas.update(LambdaTemplate(req_data.get("lambda_name")).to_json())
        new_api_resources.update(ApiGatewayTemplate(req_data.get("api_resource_name"), req_data.get("lambda_name")).to_json())
        new_ddb_tables.append(DynamoDbTemplate(req_data.get("ddb_table_name")).to_json())

    tfvars = repo.get_file(TFVARS_FILE)
    tfvars["lambdas"].update(new_lambdas)
    tfvars["api_resources"].update(new_api_resources)
    tfvars["dynamodb_tables"].extend(new_ddb_tables)

    repo.update_file(TFVARS_FILE, tfvars)
    repo.push_to_remote(request.ticket_id)