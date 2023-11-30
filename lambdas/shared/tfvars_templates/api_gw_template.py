from dataclasses import dataclass, field


@dataclass
class ApiGatewayTemplate:
    name: str
    lambda_name: str
    method: str = "POST"
    request_templates: dict = field(default_factory=dict) 
    response_templates: dict = field(default_factory=dict)
    is_html_response: bool = False
    api_key_enabled: bool = True
    authorizer_type: str = "NONE"
    type: str = "AWS_PROXY"
    cors: str = ""

    def to_json(self):
        return {
            self.name: {
                "lambda_name": self.lambda_name,
                "method": self.method,
                "request_templates": self.request_templates,
                "response_templates": {"application/json": ""} if self.response_templates == {} else self.response_templates,
                "is_html_response": self.is_html_response,
                "api_key_enabled": self.api_key_enabled,
                "authorizer_type": self.authorizer_type,
                "type": self.type,
                "cors": self.cors,
            }
        }
