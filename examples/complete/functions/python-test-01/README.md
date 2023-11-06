
# python-f5-port-reservation  

Production API:   https://mlzg5yrob8.execute-api.us-east-1.amazonaws.com/prod  
Development API:  https://yttxmrfrk1.execute-api.us-east-1.amazonaws.com/dev  

# Methods

URL: <api_gateway_base_url>/python-f5-port-reservation

## POST  

The rule name is case sensitive.

### Request:  
```json
{
  "device_id": "uat_shared_services_gov",
  "rule_name": "ODY-Generic-Prod-OMS",
  "reservation_requests": [
    {
      "customer_id": "000000",
      "deployment_id": "ABCDE",
      "reservation_type": "OMS_RESERVATON",
      "environment_name": "production"
    },
    {
      "customer_id": "000000",
      "deployment_id": "ABCDE",
      "reservation_type": "OMS_RESERVATON",
      "environment_name": "stage"
    }
  ]
}

```

#### Response:  

```json
[
  {
    "environment_name": "production",
    "customer_id": "000000",
    "port_number": 1405,
    "device_id": "uat_shared_services_gov"
  },
  {
    "environment_name": "stage",
    "customer_id": "000000",
    "port_number": 1405,
    "device_id": "uat_shared_services_gov"
  }
]


```


## Devices:

Device settings can be set in the json file: src/device_configurations.json

```json
{
    "uat_shared_services_gov":
    {
        "id": "uat_shared_services_gov",
        "name": "",
        "base_url": "https://ec2-3-30-50-213.us-gov-west-1.compute.amazonaws.com",
        "allowed_port_range_max": 1499,
        "allowed_port_range_min": 1400,
        "excluded_ports": []
    },
    "production_shared_services_gov":
    {
        "id": "production_shared_services_gov",
        "name": "production_shared_services_gov",
        "base_url": "https://ec2-52-61-175-136.us-gov-west-1.compute.amazonaws.com",
        "allowed_port_range_max": 1499,
        "allowed_port_range_min": 1400,
        "excluded_ports": [] 
    }
}
```


## Lambda Function Test Payload:

```json
{
    "resource": "/",
    "path": "/",
    "httpMethod": "POSt",
    "requestContext": {
    },
    "headers": {
    },
    "multiValueHeaders": {
    },
    "queryStringParameters": null,
    "multiValueQueryStringParameters": null,
    "pathParameters": null,
    "stageVariables": null,
    "body": {
        "device_id": "uat_shared_services_gov",
        "rule_name": "ODY-Generic-Prod-OMS",
        "reservation_requests": [
            {
                "customer_id": "000000",
                "deployment_id": "ABCDE",
                "reservation_type": "OMS_RESERVATON",
                "environment_name": "production"
            },
            {
                "customer_id": "000000",
                "deployment_id": "ABCDE",
                "reservation_type": "OMS_RESERVATON",
                "environment_name": "stage"
            }
        ]
    },
    "isBase64Encoded": false
}

```





## Environment Variables: 

| Name  | Description  | Type  | Default  | Required  |
|---|---|---|---|---|
| F5_NETWORKING_API_BASE_URL  | URL of the API gateway deployed by networking. | string |   | YES  |
| ENVIRONMENT_NAME  | Deployment evironment. | string | development  |  YES |
| F5_SECRET_NAME  | Name of the secret that contains the F5 credentials. | string |   | YES  |
| DYNAMO_DB_TABLE_NAME  | Name of the Dynamo DB table to store app data. | string|   | YES  |


## Dynamo DB Tables:





## Tables:  
Production: production-f5-resource-reservations
Development: development-f5-resource-reservations
 

| Name  | Description  | Type  | Default  | Required  |
|---|---|---|---|---|
| (PK)#DEVICE:name  | The default account number used for deployment. | string |   |  YES |
| (SK)#OMS_RESERVATON:ody-generic-prod-oms#PORT:port_number | The type of reservation used as the sort key. | string |   | YES  |
| customer_id | The number of the port that was reserved. | string |   | YES  |
| deployment_id | The number of the port that was reserved. | string |   | YES  |
| created  | The date the record was created. | string(datetime) |   | YES  |
| modified_date  | The data the record was las modified. | string(datetime) |   | YES  |  



Key Example:  
PK: #DEVICE:uat_shared_services_gov  
SK: #OMS_RESERVATON:ODY-Generic-Prod-OMS#PORT:1402  






# Process Info  

Networking will need to allow 443 traffic from the NAT Gateways the Lambda function is using.  The IPs needed are the Elasitic IPs assigned to the NAT gateways for subnets you assign use. Currently:
https://us-east-1.console.aws.amazon.com/vpc/home?region=us-east-1#NatGateways:search=vpc-0c4426569c125b835;subnetId=subnet-08f79b10e475235ed,subnet-0e7aa12ee7bb02a26,subnet-0021bd079454de683;sort=desc:subnetId  

The security group for F5 Management interface also needs updates:
IP4 | All TCP | TCP | 0 - 65535 | <NAT IP>

1. Login to F5 Device and obtain token  

POST: https://ec2-52-61-175-136.us-gov-west-1.compute.amazonaws.com/mgmt/shared/authn/login  
Body:
```json
{
    "username": "",
    "password": "",
    "loginProviderName": "tmos"
}
```

2. Get OMS Ports:  
Header:  
```json
{
    "X-F5-Auth-Token": "${loginToken}"
}

```
Odyssey Rule String: ODY-Generic-Prod-OMS  
GET: https://ec2-52-61-175-136.us-gov-west-1.compute.amazonaws.com/mgmt/tm/ltm/rule/<ruleString>  


