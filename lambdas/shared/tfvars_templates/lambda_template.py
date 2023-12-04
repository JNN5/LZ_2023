from dataclasses import dataclass, field


@dataclass
class LambdaTemplate:
    lambda_name: str
    lambda_description: str = ""
    lambda_handler: str = "handler.handler"
    lambda_file_name: str = "./handler.zip"
    lambda_memory_size: int = 512
    lambda_timeout: int = 30
    lambda_runtime: str = "python3.11"
    layers: list = field(default_factory=list)
    kms_key: str = "lz-lambda-key"
    in_vpc: bool = False
    environment_variables: list = field(default_factory=list)

    def to_json(self):
        return {
            self.lambda_name: {
                "lambda_description": self.lambda_description,
                "lambda_handler": self.lambda_handler,
                "lambda_file_name": self.lambda_file_name,
                "lambda_memory_size": self.lambda_memory_size,
                "lambda_timeout": self.lambda_timeout,
                "lambda_runtime": self.lambda_runtime,
                "layers": self.layers,
                "kms_key": self.kms_key,
                "in_vpc": self.in_vpc,
                "environment_variables": self.environment_variables,
            }
        }
