from lambdas.handler import handler
from . import test_data


class TestHandler:
    def test_func(self, lambda_context):
        res = handler(test_data.event, lambda_context)
        assert res["statusCode"] == 200