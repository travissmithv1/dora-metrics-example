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


def does_issue_exist(cursor, issue_id):
    query = f"SELECT id FROM issue WHERE issue_id = \'{issue_id}\'"
    cursor.execute(query)
    return cursor.fetchone() is not None


def update_existing_issue(cursor, issue_id, resolution_deployment_id):
    query = f"update issue set resolution_deployment_id = \'{resolution_deployment_id}\' where issue_id = \'{issue_id}\'"
    cursor.execute(query)


def create_new_issue(cursor, issue_id, originated_deployment_id, resolution_deployment_id=None):
    new_issue_id = uuid.uuid4()
    created_on = datetime.datetime.now(datetime.timezone.utc)

    if resolution_deployment_id:
        query = f"insert into issue (id, issue_id, originated_deployment_id, resolution_deployment_id, created_on) " \
                f"select \'{new_issue_id}\', \'{issue_id}\', \'{originated_deployment_id}\', " \
                f"\'{resolution_deployment_id}\', \'{created_on}\'"
    else:
        query = f"insert into issue (id, issue_id, originated_deployment_id, created_on) " \
                f"select \'{new_issue_id}\', \'{issue_id}\', \'{originated_deployment_id}\', " \
                f"\'{created_on}\'"
    cursor.execute(query)

def record_issue(event, context):
    credentials = fetch_secret_credentials()
    connection = establish_db_connection(credentials)
    cursor = connection.cursor()

    project_id = event['project_id']
    issue_id = event['issue_id']
    originated_release_tag = event['originated_release_tag']
    resolution_release_tag = event.get('resolution_release_tag')

    originated_deployment_id = find_deployment_id(cursor, project_id, originated_release_tag)
    resolution_deployment_id = find_deployment_id(cursor, project_id, resolution_release_tag) if resolution_release_tag else None

    if does_issue_exist(cursor, issue_id):
        if resolution_deployment_id:
            update_existing_issue(cursor, issue_id, resolution_deployment_id)
    else:
        create_new_issue(cursor, issue_id, originated_deployment_id, resolution_deployment_id)

    connection.commit()
    cursor.close()

    return {
        'statusCode': 200,
        'body': json.dumps('Issue recorded successfully!')
    }
