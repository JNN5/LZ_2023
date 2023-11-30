from git import Repo
import json


class GitRepo:
    _repo: Repo
    _local_dir: str

    def __init__(self, remote_url: str, local_dir: str):
        try:
            self._repo = Repo(local_dir)
        except Exception:
            self._repo = Repo.clone_from(remote_url, local_dir)
        self._local_dir = local_dir

    def get_file(self, file: str) -> dict:
        with open(f"{self._local_dir}/{file}") as f:
            return json.load(f)

    def update_file(self, file: str, content: dict):
        with open(f"{self._local_dir}/{file}", "w") as f:
            f.write(json.dumps(content))

        add_file = [file]  # relative path from git root
        self._repo.index.add(add_file)

    def push_to_remote(self, commit_msg: str):
        self._repo.index.commit(commit_msg)
        self._repo.remote(name="origin").push()
