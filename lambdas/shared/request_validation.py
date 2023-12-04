from dataclasses import Field, dataclass, fields
import re
import datetime
import json
from api_response_handler import BadRequest


def parse_event(event: dict, clazz: dataclass):
    if event.get("body-json"):
        body = event.get("body-json")
    elif event.get("body"):
        body = _parse_event_body(event)
    else:
        body = event
    required_fields = _get_required_class_fields(clazz)
    all_fields = _get_all_class_fields(clazz)
    if not all(elem in list(body.keys()) for elem in required_fields):
        raise BadRequest(
            f"{event} does not contain all of these fields {required_fields}"
        )
    elif any(elem not in all_fields for elem in list(body.keys())):
        raise BadRequest(f"{event} contains fields that are not expected {all_fields}")
    try:
        return clazz(*[_parse_field_from_event(f, body) for f in fields(clazz)])
    except Exception as e:
        raise BadRequest(f"Unable to parse event: {event}. Error: {e}")


def _parse_field_from_event(f: Field, body: dict):
    value = body.get(f.name, None)
    regex = f.metadata.get("regex", None)
    date_format = f.metadata.get("date_format", None)
    if value is None:
        return None
    elif date_format is not None:
        return datetime.datetime.strptime(value, date_format)
    elif regex is not None and re.findall(regex, value) == []:
        raise BadRequest(
            f"{value} is not a valid format for field {f.name}. It has to conform to this regex: {regex}"
        )
    else:
        return value


def _get_required_class_fields(clazz: dataclass):
    # We want to filter out Optional types.
    # Optional means a Union of some type with a None type
    # Hence, we can check that the type definition does not include a None type
    return [
        x.name
        for x in fields(clazz)
        if hasattr(x.type, "__args__") == False or type(None) not in x.type.__args__
    ]


def _get_all_class_fields(clazz: dataclass):
    return [x.name for x in fields(clazz)]


def _parse_event_body(event: dict):
    try:
        return json.loads(event.get("body"))
    except Exception as e:
        raise BadRequest(
            f"Unexpected format of input event: {event}. Parsing failed due to error: {e}"
        )
