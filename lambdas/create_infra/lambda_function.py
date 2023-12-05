from datetime import datetime
import os
import sys
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.logging.correlation_paths import API_GATEWAY_REST

sys.path.append(os.path.dirname(os.path.realpath(__file__)))
sys.path.append(os.path.join(os.path.dirname(__file__), "shared"))
from shared.git_repo import Repo
from shared.service_now_dto import ServiceNowDto, REQUEST_CONFIG
from shared.request_validation import parse_event
from shared.api_response_handler import as_api
from shared.tfvars_templates.lambda_template import LambdaTemplate
from shared.tfvars_templates.api_gw_template import ApiGatewayTemplate
from shared.tfvars_templates.dynamodb_template import DynamoDbTemplate
from shared.request_model import RequestModel
from shared.commit_message import CommitMessage


CORS = "*"

REPO = os.environ.get("REPO", "CAG-CodeRepo")
TFVARS_FILE = os.environ.get("TFVARS_FILE", "tfvars.json")

log = Logger()
tracer = Tracer()


@tracer.capture_lambda_handler
@log.inject_lambda_context(correlation_id_path=API_GATEWAY_REST, log_event=True)
@as_api(CORS)
def lambda_handler(event, context):
    request: ServiceNowDto = parse_event(event, ServiceNowDto)
    config = REQUEST_CONFIG[request.app_type.lower()][request.app_size.upper()]

    new_lambdas, new_api_resources, new_ddb_tables = create_new_tf_vars(config)

    trigger_iac_pipeline(request, new_lambdas, new_api_resources, new_ddb_tables)

    save_request(request)

    return {
        "new_lambdas": new_lambdas,
        "new_api_resources": new_api_resources,
        "new_ddb_tables": new_ddb_tables,
    }


def trigger_iac_pipeline(request, new_lambdas, new_api_resources, new_ddb_tables):
    repo = Repo(REPO)
    tfvars = repo.get_file(TFVARS_FILE)
    tfvars["lambdas"].update(new_lambdas)
    tfvars["api_resources"].update(new_api_resources)
    tfvars["dynamodb_tables"].extend(new_ddb_tables)

    repo.update_file(TFVARS_FILE, tfvars, CommitMessage.generate(request.ticket_id))


def create_new_tf_vars(config):
    new_lambdas = {}
    new_api_resources = {}
    new_ddb_tables = []

    for _ in range(int(config.get("lambda", 0))):
        lambda_name = now()
        api_resource_name = now()
        new_lambdas.update(LambdaTemplate(lambda_name).to_json())
        new_api_resources.update(
            ApiGatewayTemplate(api_resource_name, lambda_name).to_json()
        )

    for _ in range(int(config.get("ddb", 0))):
        table_name = now()
        new_ddb_tables.append(DynamoDbTemplate(table_name).to_json())
    return new_lambdas, new_api_resources, new_ddb_tables


def now():
    return datetime.now().strftime("%Y-%m-%dT%H_%M_%S_%f")


def save_request(request):
    model = RequestModel.setup_model()
    model(
        request.ticket_id,
        request.workflow,
        requester=request.requester,
        requested_for=request.requested_for,
        requested_at=request.requested_at,
        app_type=request.app_type,
        app_size=request.app_size,
    ).save()
