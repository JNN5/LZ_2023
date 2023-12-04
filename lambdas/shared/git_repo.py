from boto3 import client
import json


class Repo:
    client: client
    repo: str

    def __init__(self, repo: str):
        self.client = client("codecommit")
        self.repo = repo

    def get_file(self, file: str) -> dict:
        return json.loads(
            self.client.get_file(repositoryName=self.repo, filePath=file)
            .get("fileContent")
            .decode("utf-8")
        )

    def update_file(self, file: str, content: dict, commit_msg: str):
        branch = self.client.get_branch(repositoryName=self.repo, branchName="main")
        self.client.put_file(
            repositoryName=self.repo,
            branchName="main",
            filePath=file,
            fileContent=json.dumps(content),
            parentCommitId=branch["branch"]["commitId"],
            commitMessage=commit_msg,
        )
