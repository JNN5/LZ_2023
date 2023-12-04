from dataclasses import dataclass
from datetime import datetime

from request_validation import parse_event


@dataclass
class ServiceNowDto:
    ticket_id: str
    requester: str
    requested_for: str
    requested_at: str
    workflow: str
    app_type: str
    app_size: str


REQUEST_CONFIG = {
    "serverless": {
        "S": {
            "lambda": 1,
            "ddb": 1,
        },
        "M": {
            "lambda": 5,
            "ddb": 3,
        },
        "L": {
            "lambda": 10,
            "ddb": 5,
        },
    }
}
