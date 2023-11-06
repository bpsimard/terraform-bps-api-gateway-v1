import json
import os
import datetime
from botocore.exceptions import ClientError
import requests
from datetime import datetime, date
from boto3.dynamodb.conditions import Key, Attr
import base64
import boto3
import logging

#Initialize logger and set log level
log = logging.getLogger()
log.setLevel(logging.INFO)


F5_BASE_URL = os.environ.get('F5_BASE_URL')
F5_NETWORKING_API_BASE_URL = os.environ.get('F5_NETWORKING_API_BASE_URL')
DYNAMO_DB_TABLE_NAME = os.environ.get('DYNAMO_DB_TABLE_NAME',None)
F5_SECRET_NAME = os.environ.get('F5_SECRET_NAME')
DYNAMO_DB_TABLE_NAME = os.environ.get('DYNAMO_DB_TABLE_NAME')


REGION = os.environ.get('AWS_REGION',os.environ.get('AWS_DEFAULT_REGION'))


def f5_login(username,password, f5_base_url):
    #print(F5_NETWORKING_API_BASE_URL)
    url = f5_base_url + "/mgmt/shared/authn/login"
    data = {"username": username, "password": password, "loginProviderName": "tmos"}
    jsondata = json.dumps(data)
    return requests.post(url,data = jsondata, verify=False)


def get_f5_port_usage(headers,f5_base_url, f5_rule_string):
    #print(F5_NETWORKING_API_BASE_URL)
    url = f"{f5_base_url}/mgmt/tm/ltm/rule/" + f5_rule_string
    #jsondata = json.dumps(data)
    return requests.get(url,headers=headers, verify=False)



def get_items_by_device_id(device_id):
    try:
        pk = f"#DEVICE:{device_id}"
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(DYNAMO_DB_TABLE_NAME)
        response = table.query(KeyConditionExpression=Key("PK").eq(pk))
        if response['ResponseMetadata']['HTTPStatusCode'] == 200:
            return response['Items']

    except Exception as exception:
        log.error('Error while getting records from DDB')
        log.error(str(exception))
        log.info('EOE')
        return False


def add_item(device_id, rule_string, port_number, deployment_id, customer_id, environment_name):
    try:
        sk = f"#OMS_RESERVATON:{rule_string}#PORT:{port_number}"
        pk = f"#DEVICE:{device_id}" 
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(DYNAMO_DB_TABLE_NAME)
        response = table.put_item(
            Item={
                    "PK": pk,
                    "SK": sk,
                    "DeviceId": device_id,
                    "EnvironmentName": environment_name,
                    "CustomerId": customer_id,
                    "DeploymentId": deployment_id,
                    "RuleString": rule_string,
                    "PortNumber": port_number

            }
        )
        if response['ResponseMetadata']['HTTPStatusCode'] != 200:
            #log.info(response)
            print(response)
            return True

    except Exception as exception:
        log.error('Error while updating DDB')
        log.error(str(exception))
        log.info('EOE')
        return False

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
 
def get_f5_gov_secret(secretKey):
    secret = get_secrets_manager_secret(secretKey)
    myCredential = {}
    myCredential['username'] = secret.get('user_name',None)
    myCredential['password'] = secret.get('password',None)
    return myCredential


def getInUserOMSPorts(f5OMSPortReturn):
    if f5OMSPortReturn != None:
        splitOnProds = f5OMSPortReturn.lower().split('prod-')
        for splitOnProd in splitOnProds:
            splitOnProd.split("}")
    return splitOnProd

def get_used_oms_ports_from_f5_return2(f5Return):
    r = f5Return
    portList = []
    print("HERE")
    print(r.json())



def get_used_oms_ports_from_f5_return(f5Return):
    r = f5Return.json()
    portList = []
    for rr in r['apiAnonymous'].lower().split('prod-'):
        splitOnBracket = rr.split('}')
        for rrr in splitOnBracket:
            splitOnBracket2 = rrr.split('{')
            for rrrr in splitOnBracket2:
                noWhiteSpaces = rrrr.replace(" ", "")
                try:
                    string_int = int(noWhiteSpaces)
                    portList.append(string_int)
                except ValueError:
                    # Handle the exception
                    a = 1
                    #print('Failed to convert to integer.')
    return portList

def getNextInt(list_num):
    x = 0
    try:
        x = next(val for val in range(x) if val not in list_num)
    except:
        x = 0
    return x

def get_f5_response_mock():
    mock = "f5_get_port_mock.txt"
    with open(mock, 'r') as f:
        mock_configuration = json.load(f)
    return mock_configuration
    
def get_device_configurations(device_id):
    device_configurations_file_path = f"device_configurations.json"
    with open(device_configurations_file_path, 'r') as f:
        device_configurations = json.load(f)
    return device_configurations[device_id]

def post(body_json):
    return_results = []    
    f5_rule_string = body_json["rule_name"]
    reservation_requests = body_json["reservation_requests"]
    this_device_id = body_json["device_id"]
    device_configuration = get_device_configurations(this_device_id)
        
    ### Get Current Requests
    existing_port_reservations = get_items_by_device_id(this_device_id)
    #print("Records:")
    #print(existing_port_reservations)
    existing_port_reservations_for_rule = [r["PortNumber"] for r in existing_port_reservations if r["RuleString"] == f5_rule_string ]
    #print("Resrved Ports Ports")
    #print(existing_port_reservations_for_rule)       
    for reservation_request in reservation_requests:
        print("HERE")
        print(reservation_request)
        reservation_environment = reservation_request["environment_name"]
        customer_id = reservation_request["customer_id"]
        deployment_id = reservation_request["deployment_id"]
        this_device_base_url = device_configuration["base_url"]      
        allowed_port_range = range(device_configuration["allowed_port_range_min"], device_configuration["allowed_port_range_max"])
        exclude_specific_ports = device_configuration["excluded_ports"]

        log.info("Getting the next available F5 port.")
        useMock = False
            
        print(f"Request for port reservation for device {this_device_id} using rule string: {f5_rule_string}")

        if useMock == True:
            f5_get_ports_mock = get_f5_response_mock()
            usedPortListFromF5 = get_used_oms_ports_from_f5_return(f5_get_ports_mock)     
        else:
            f5Secret = get_f5_gov_secret(F5_SECRET_NAME)
            f5_login_return = f5_login(f5Secret['username'],f5Secret['password'], this_device_base_url).json()
            headers = {'X-F5-Auth-Token': f5_login_return["token"]["token"]}
            f5_port_usage_return = get_f5_port_usage(headers, this_device_base_url, f5_rule_string)
            usedPortListFromF5 = get_used_oms_ports_from_f5_return(f5_port_usage_return)
                
        print(f"Used F5 Ports: {usedPortListFromF5}")
            
        ### Remove Used ports
        unused_ports = [r for r in allowed_port_range if str(r) not in usedPortListFromF5]
        ### Remove excluded ports
        unused_ports = [r for r in unused_ports if str(r) not in exclude_specific_ports]
        ### excluded cached ports
        unused_ports = [r for r in unused_ports if str(r) not in existing_port_reservations_for_rule]
        next_port = unused_ports[0]
        log.info("Next Port Available: " + str(next_port))
            
        print(f"Reserving Port: {next_port} for Rule: {f5_rule_string} on Device: {this_device_id}")
        add_item(f"{this_device_id}", f"{f5_rule_string}", f"{next_port}", deployment_id, customer_id, reservation_environment )
        existing_port_reservations_for_rule.append(str(next_port))
            
        data = {
            "environment_name": reservation_environment,
            "customer_id": customer_id,
            "port_number": next_port,
            "device_id": this_device_id
        }
        return_results.append(data)

    return return_results
    

def lambda_handler(event, context): 
    body = str(event["body"])
    #print(body)
    body = body.replace("'",'"')
    body = body.replace('\"','"')
    body_json = json.loads(str(body))
    actions = { 'POST': 'CREATE', 'PUT': 'UPSERT', 'DELETE': 'DELETE' }
    action = event.get('httpMethod', None)
    return_results = None
    print(f"Running {action}")
    status_code = 0
    if action == "POST":
        return_results = post(body_json)
        status_code = 200
    else:
        status_code = 405
        pass
    return_result_response = {
        "isBase64Encoded": True,
        "statusCode": status_code,
        "headers": { },
        "body": json.dumps(return_results)
    }
    print("Return Result:")
    print(return_result_response)
    return return_result_response