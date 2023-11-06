import json
import os
import datetime
from botocore.exceptions import ClientError
import requests
from datetime import datetime, date
import base64
import boto3
import logging

#Initialize logger and set log level
log = logging.getLogger()
log.setLevel(logging.INFO)

SECRET_NAME = os.environ.get('SECRET_NAME')
REGION = os.environ.get('AWS_REGION',os.environ.get('AWS_DEFAULT_REGION'))



def get_secrets_manager_secret(secretKey):
     # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=REGION
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secretKey
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'AccessDeniedException':
            # Access denied fetching secret
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        secret = {}
    else:
        # Decrypts secret using the associated KMS key.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            log.info('parsing SecretString value')
            secret = json.loads(get_secret_value_response['SecretString'])
            return secret
        else:
            log.info('parsing SecretBinary value')
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
            return decoded_binary_secret
 
def get_secret(secretKey):
    secret = get_secrets_manager_secret(secretKey)
    myCredential = {}
    myCredential['username'] = secret.get('user_name',None)
    myCredential['password'] = secret.get('password',None)
    return myCredential

def lambda_handler(event, context):
    secret_value = get_secret(SECRET_NAME)
    return 0



lambda_handler(None, None)