from lambdas.create_infra.lambda_function import lambda_handler
from . import test_data


class TestHandler:
    def test_func(self, monkeypatch, lambda_context):
        monkeypatch.setattr("lambdas.shared.git_repo.Repo.get_file", {})
        monkeypatch.setattr("lambdas.shared.git_repo.Repo.update_file", None)
        res = lambda_handler(test_data.event, lambda_context)
        assert res["statusCode"] == 200
