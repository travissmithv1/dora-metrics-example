import psycopg2
import json
import urllib.parse
import os
import requests
import uuid
import datetime


def fetch_secret_credentials():
    aws_token = os.environ.get('AWS_SESSION_TOKEN')
    secret_name = "[INSERT_AWS_SECRET_NAME_HERE]"
    secret_request_url = f"http://localhost:2773/secretsmanager/get?secretId={urllib.parse.quote(secret_name)}"

    response = requests.get(secret_request_url, headers={"X-Aws-Parameters-Secrets-Token": aws_token})
    secret_data = eval(json.loads(response.text)["SecretString"])

    return {'USER_NAME': secret_data["username"], 'PASSWORD': secret_data["password"]}


def establish_db_connection(credentials):
    return psycopg2.connect(
        user=credentials['USER_NAME'],
        password=credentials['PASSWORD'],
        host='[INSERT_DATABASE_HOST_URL_HERE]',
        port='[INSERT_DATABASE_PORT_HERE]',
        dbname='[INSERT_DATABASE_NAME_HERE]'
    )

def find_deployment_id(cursor, project_id, release_tag):
    query = f"select id from deployment where release_tag = \'{release_tag}\' and project_id = \'{project_id}\'"
    cursor.execute(query)
    deployment = cursor.fetchone()
    return str(deployment[0]) if deployment else None


def insert_commit(cursor, commit_id, committed_on, deployment_id):
    new_commit_id = uuid.uuid4()
    created_on = datetime.datetime.now(datetime.timezone.utc)

    query = f"insert into commit (id, commit_id, committed_on, deployment_id, created_on) " \
            f"select \'{new_commit_id}\', \'{commit_id}\', \'{committed_on}\', " \
            f"\'{deployment_id}\', \'{created_on}\'"
    cursor.execute(query)

def record_commit(event, context):
    credentials = fetch_secret_credentials()
    connection = establish_db_connection(credentials)
    cursor = connection.cursor()

    project_id = event['project_id']
    commit_id = event['commit_id']
    committed_on = event['committed_on']
    release_tag = event['release_tag']

    deployment_id = find_deployment_id(cursor, project_id, release_tag)

    insert_commit(cursor, commit_id, committed_on, deployment_id)

    connection.commit()
    cursor.close()

    return {
        'statusCode': 200,
        'body': json.dumps('Commit recorded successfully!')
    }
