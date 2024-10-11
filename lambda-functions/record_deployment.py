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

def insert_deployment(cursor, project_id, release_tag, deployed_on, repository_name):
    deployment_id = uuid.uuid4()
    created_on = datetime.datetime.now(datetime.timezone.utc)

    query = f"insert into deployment (id, project_id, release_tag, deployed_on, created_on, repository_name) " \
            f"select \'{deployment_id}\', \'{project_id}\', \'{release_tag}\', " \
            f"\'{deployed_on}\', \'{created_on}\', \'{repository_name}\'"
    cursor.execute(query)

def record_deployment(event, context):
    credentials = fetch_secret_credentials()
    connection = establish_db_connection(credentials)
    cursor = connection.cursor()

    project_id = event['project_id']
    deployed_on = event['deployed_on']
    release_tag = event['release_tag']
    repository_name = event['repository_name']

    insert_deployment(cursor, project_id, release_tag, deployed_on, repository_name)

    connection.commit()
    cursor.close()

    return {
        'statusCode': 200,
        'body': json.dumps('Deployment recorded successfully!')
    }
