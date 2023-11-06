### ROTATING IAM Access Key  ###
import boto3
from datetime import date
import json

def whoami(aws_access_key_id=None, aws_secret_access_key=None):
    if aws_access_key_id is None or aws_secret_access_key is None:
        print("Using current session")
        sts = boto3.client('sts') 
    else:
        print("Generating session for " + aws_access_key_id)
        botosession=boto3.Session(
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key
        )
        sts = botosession.client('sts')
        
    response = sts.get_caller_identity()
    data = {}
    for field in ['Account', 'Arn', 'UserId']:
        data[field] = response[field]

    data['Type'], name = data['Arn'].rsplit(':', 1)[1].split('/',1)
    data['Path'] = name
    usernameArr = name.split("/")
    if (len(usernameArr) > 1):
        name = usernameArr[-1]

    if data['Type'] == 'assumed-role':
        data['Name'], data['RoleSessionName'] = name.rsplit('/', 1)
    else:
        data['Name'] = name
        data['RoleSessionName'] = None

    if data['Type'] == 'assumed-role' and data['Name'].startswith('AWSReservedSSO'):
        try:
            # format is AWSReservedSSO_{permission-set}_{random-tag}
            data['SSOPermissionSet'] = data['Name'].split('_', 1)[1].rsplit('_', 1)[0]
        except Exception as e:
            data['SSOPermissionSet'] = None
    else:
        data['SSOPermissionSet'] = None

    return data

def listAccessKeysForUser(user_name, aws_access_key_id=None, aws_secret_access_key=None):
    current_date = date.today()
    if aws_access_key_id is None or aws_secret_access_key is None:
        iam = boto3.client('iam')
    else:
        botosession=boto3.Session(
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key
        )

        iam = botosession.client('iam')
    all_data = []
    aws_access_key_ids = iam.list_access_keys(UserName=user_name)
    for key_meta in aws_access_key_ids['AccessKeyMetadata']:
        data = {}
        for field in ['UserName', 'AccessKeyId', 'Status','CreateDate']:
            data[field] = key_meta[field]
            create_date = key_meta['CreateDate'].date()
            days_old = current_date - create_date
            data['DaysOld'] = days_old
        all_data.append(data)
    return all_data
        
def deleteIamAccessKey(access_key_id, user_name, aws_access_key_id=None, aws_secret_access_key=None):
    if aws_access_key_id is None or aws_secret_access_key is None:
        iam = boto3.client('iam')
    else:
        botosession=boto3.Session(
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key
        )
        iam = botosession.client('iam')
    
    iam.delete_access_key(
        AccessKeyId=access_key_id,
        UserName=user_name
    )

def inactivateIamAccessKey(access_key_id, user_name, aws_access_key_id=None, aws_secret_access_key=None):
    if aws_access_key_id is None or aws_secret_access_key is None:
        iam = boto3.client('iam')
    else:
        botosession=boto3.Session(
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key
        )
        iam = botosession.client('iam')
    
    resp = iam.update_access_key(
        AccessKeyId=access_key_id,
        Status='Inactive',
        UserName=user_name
    )
    
    if resp['ResponseMetadata']['HTTPStatusCode'] == 200:
        print('Success!  RequestId: ' + resp['ResponseMetadata']['RequestId'])
    else:
        print('Failure!  RequestId: ' + resp['ResponseMetadata']['RequestId'])
        return
          
def generateIamAccessKey(user_name, aws_access_key_id=None, aws_secret_access_key=None):
    if aws_access_key_id is None or aws_secret_access_key is None:
        access_keys = listAccessKeysForUser(user_name)
        iam = boto3.client('iam')
    else:
        access_keys = listAccessKeysForUser(user_name, aws_access_key_id, aws_secret_access_key)
        botosession=boto3.Session(
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key
        )
        iam = botosession.client('iam')

    if len(access_keys) > 1:
        print('Unable to generate a new key, the max number of keys already exist for ' + user_name)
        return False
    createdKey = iam.create_access_key(
        UserName=user_name
    )
    ret_key = {}
    ret_key['UserName'] = createdKey['AccessKey']['UserName']
    ret_key['AccessKey'] = createdKey['AccessKey']['AccessKeyId']
    ret_key['SecretKey'] = createdKey['AccessKey']['SecretAccessKey']
    return ret_key    