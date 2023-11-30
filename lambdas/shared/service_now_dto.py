from dataclasses import dataclass
from datetime import datetime

from request_validation import parse_event





@dataclass
class Serverless:
    lambda_name: str
    api_resource_name: str
    ddb_table_name: str


@dataclass
class ServiceNowDto:
    ticket_id: str
    requester: str
    requested_at: str
    workflow: str
    request_data: [Serverless]
