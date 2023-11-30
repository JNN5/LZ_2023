from datetime import datetime
import json

def now():
    return datetime.now().strftime("%Y-%m-%dT%H_%M_%S_%f")

event = {
    "body": json.dumps({
        "ticket_id": "1234",
        "requester": "Jonas",
        "requested_at": "today",
        "workflow": "serverless app",
        "request_data": [{
          "lambda_name": now(),
          "api_resource_name": now(),
          "ddb_table_name": now(),
        }],
    })
}
