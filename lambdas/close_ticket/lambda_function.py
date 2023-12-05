import json
import requests
import boto3
import os
import sys
from aws_lambda_powertools import Logger, Tracer

sys.path.append(os.path.dirname(os.path.realpath(__file__)))
sys.path.append(os.path.join(os.path.dirname(__file__), "shared"))
from shared.commit_message import CommitMessage

log = Logger()
tracer = Tracer()

REPO = os.environ.get("REPO", "CAG-CodeRepo")
SNOW_URL = os.environ.get("SNOW_URL", "https://demoallwf44461.service-now.com/api/now/table/sc_req_item/")

code_pipeline = boto3.client("codepipeline")
code_commit = boto3.client("codecommit")
ssm = boto3.client("ssm")


@tracer.capture_lambda_handler
@log.inject_lambda_context(log_event=False)
def lambda_handler(event, context):
    try:
        # Extract the Job ID
        job_id = event["CodePipeline.job"]["id"]

        # Extract the Job Data
        job_data = event["CodePipeline.job"]["data"]
        log.info(job_data)

        commit_id = job_data["inputArtifacts"][0]["revision"]
        log.info(commit_id)

        ticket_id = get_ticket_id(commit_id)
        log.info(ticket_id)

        if ticket_id: 
            close_ticket(ticket_id)

        put_job_success(job_id)
    except Exception as e:
        put_job_failure(job_id, e)
        raise e


def put_job_success(job_id):
    code_pipeline.put_job_success_result(jobId=job_id)


def put_job_failure(job_id, message):
    log.error(message)
    code_pipeline.put_job_failure_result(
        jobId=job_id, failureDetails={"message": message, "type": "JobFailed"}
    )


def continue_job_later(job, message):
    continuation_token = json.dumps({"previous_job_id": job})

    log.info(message)
    code_pipeline.put_job_success_result(
        jobId=job, continuationToken=continuation_token
    )


def get_ticket_id(commit_id):
    commit_message = code_commit.get_commit(repositoryName=REPO, commitId=commit_id)[
        "commit"
    ].get("message", "")
    try: 
        return CommitMessage.parse_ticket_id(commit_message)
    except Exception:
        return None


def close_ticket(ticket_id):
    try:
        uri = f"{SNOW_URL}{ticket_id}"
        user = get_ssm_param("CAG_SNOW_USER", False)
        pw = get_ssm_param("CAG_SNOW_PW", False)
        headers = {'Content-Type': 'application/json', 'Accept': 'application/json'}
        data = json.dumps({'state':5})
        res = requests.put(uri, auth=(user, pw), headers=headers, data=data)
        log.info(res.text)
    except Exception as e:
        log.error(e)


def get_ssm_param(param_name, encryption=False):
    ssm_response = ssm.get_parameter(
            Name=param_name, WithDecryption=encryption
        )
    return ssm_response.get("Parameter", {}).get("Value")