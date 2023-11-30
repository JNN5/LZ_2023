from dataclasses import dataclass
import json
from aws_lambda_powertools import Logger
from response import ApiGwResponse

class NotFoundError(Exception):
    pass

class BadRequest(Exception):
    pass

class Unauthorized(Exception):
    pass

class Forbidden(Exception):
    pass

log = Logger()

def as_api(cors = None):
    def api_response_handler(func):
        def lambda_wrapper(event, context, **kwargs):

            try:
                return ApiGwResponse(200, func(event, context, **kwargs), cors=cors).to_json()
            except BadRequest as e:
                log.warning(e)
                return ApiGwResponse(400, cors=cors).to_json()
            except Unauthorized as e:
                log.warning(e)
                return ApiGwResponse(401, cors=cors).to_json()
            except Forbidden as e:
                log.warning(e)
                return ApiGwResponse(403, cors=cors).to_json()
            except NotFoundError as e:
                log.warning(e)
                return ApiGwResponse(404, cors=cors).to_json()
            except Exception as e:
                log.exception(e)
                return ApiGwResponse(500, cors=cors).to_json()
        
        return lambda_wrapper
    return api_response_handler

