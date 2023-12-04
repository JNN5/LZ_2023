from datetime import datetime
import json


def now():
    return datetime.now().strftime("%Y-%m-%dT%H_%M_%S_%f")


event = {
    "body-json": {
        "ticket_id": "1234",
        "requester": "Jonas",
        "requested_for": "Jonas",
        "requested_at": "today",
        "workflow": "application onboarding",
        "app_type": "serverless",
        "app_size": "M",
    },
    "params": {
        "path": {},
        "querystring": {},
        "header": {
            "Accept": "*/*",
            "accept-encoding": "gzip, deflate, br",
            "Content-Type": "application/json",
            "Host": "yypzwgry45.execute-api.ap-southeast-1.amazonaws.com",
            "User-Agent": "Thunder Client (https://www.thunderclient.com)",
            "X-Amzn-Trace-Id": "Root=1-65680cb4-4f0267c9735624203df48c55",
            "x-api-key": "5FU5JGyHaR4GXpOuM2QFy1JQU9noLLk59fPD1jMH",
            "X-Forwarded-For": "103.4.197.233",
            "X-Forwarded-Port": "443",
            "X-Forwarded-Proto": "https",
        },
    },
}
