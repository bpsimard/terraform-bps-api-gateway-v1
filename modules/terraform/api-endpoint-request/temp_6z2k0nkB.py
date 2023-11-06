import requests
import json
import sys
import os
import string
import random
import subprocess
import urllib.parse



# from secrets import secrets

cred_output = ""
role_arn = sys.argv[1]
api_secret_name = sys.argv[2]
endpoint_url = sys.argv[3]
endpoint_url_append = sys.argv[4]
authentiction_type = sys.argv[5]
method = sys.argv[6]
payload = sys.argv[7]

if payload != None:
    payload = payload.replace('\n','')
    payload = payload.replace('\"','"')
    payload = payload.replace('\\n','')
    payload = payload.replace('\\"','"')

data = json.loads(payload)
#data = payload
endpoint = endpoint_url
if endpoint_url_append != "none":
    endpoint = f"{endpoint_url}{endpoint_url_append}"
endpoint_url = urllib.parse.quote(endpoint)
random_string = ''.join(random.choices(string.ascii_lowercase +
                             string.digits, k=8))
AWS_ACCESS_KEY_ID = os.environ["AWS_ACCESS_KEY_ID"]
AWS_DEFAULT_REGION = os.environ["AWS_DEFAULT_REGION"]
#print(os.environ["AWS_ACCESS_KEY_ID"])
cred_command = f"aws sts assume-role --role-arn {role_arn} --role-session-name ssm_api_execute{random_string} --output json"
print(cred_command)
try:
    cred_output = subprocess.check_output(cred_command, stderr=subprocess.STDOUT, shell=True)
except Exception as e:
    #print(cred_output)
    print("There was an error assuming role {role_arn} in {AWS_DEFAULT_REGION} with key {AWS_ACCESS_KEY_ID}")
    print(f"Error {e}")
#print(cred_output)

creds = json.loads(cred_output)
os.environ["AWS_ACCESS_KEY_ID"] = creds["Credentials"]["AccessKeyId"]
os.environ["AWS_SECRET_ACCESS_KEY"] = creds["Credentials"]["SecretAccessKey"]
os.environ["AWS_SESSION_TOKEN"] = creds["Credentials"]["SessionToken"]

api_secret_command = f"aws secretsmanager get-secret-value --secret-id {api_secret_name} --output json"
api_secret = subprocess.check_output(api_secret_command, stderr=subprocess.STDOUT, shell=True)

api_secret_json = json.loads(api_secret)
api_secret_string = json.loads(api_secret_json["SecretString"])

### Make headers
headers = {}
response = None
if authentiction_type == "basic":
    username = api_secret_string["username"]
    password = api_secret_string["password"]
    headers = {"Content-Type": "application/json"}

if authentiction_type == "bearer":
    token = api_secret_string["token"]
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

if authentiction_type == "x-api-key":
    token = api_secret_string["x-api-key"]
    headers = {"x-api-key": f"{token}", "Content-Type": "application/json"}

if authentiction_type == "hmac":
    token = api_secret_string["token"]
    headers = {"Content-Type": "application/json"}

print(f"Using endpoint: {endpoint} Method: {method} with payload: {data}")


### Send Request
response = None
if authentiction_type == "basic":
    if method == "post":
        response = requests.post((endpoint),headers=headers,json=data, auth=(username,password))
    if method == "put":
        response = requests.put((endpoint),headers=headers,json=data, auth=(username,password))
    if method == "get":
        response = requests.get((endpoint),headers=headers,json=data, auth=(username,password))
    if method == "patch":
        response = requests.patch((endpoint),headers=headers,json=data, auth=(username,password))
else:
    if method == "post":
        response = requests.post((endpoint),headers=headers,json=data)
    if method == "put":
        response = requests.put((endpoint),headers=headers,json=data)
    if method == "get":
        response = requests.get((endpoint),headers=headers,json=data)
    if method == "patch":
        response = requests.patch((endpoint),headers=headers,json=data)

request_response_json = response.json
request_response_text = response.text
print()
print()
print("")
print(f"Request Response: {request_response_json}    Request: {payload}")
print(f"Route53 Request Id: {request_response_text}     Request: {payload}")


