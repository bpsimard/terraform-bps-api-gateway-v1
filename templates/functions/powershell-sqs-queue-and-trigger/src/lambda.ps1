# PowerShell script file to be executed as a AWS Lambda function.
#
# When executing in Lambda the following variables will be predefined.
#   $LambdaInput - A PSObject that contains the Lambda function input data.
#   $LambdaContext - An Amazon.Lambda.Core.ILambdaContext object that contains information about the currently running Lambda environment.
#
# The last item in the PowerShell pipeline will be returned as the result of the Lambda function.
#
# To include PowerShell modules with your Lambda function, like the AWS.Tools.S3 module, add a "#Requires" statement
# indicating the module and version. If using an AWS.Tools.* module the AWS.Tools.Common module is also required.
#
# This example demonstrates how to process an SQS Queue:
# SQS Queue -> Lambda Function

#Requires -Modules @{ModuleName='AWS.Tools.Common';ModuleVersion='4.0.5.0'}
#Requires -Modules ActiveDirectory
#Requires -Modules AWSPowerShell

# Uncomment to send the input event to CloudWatch Logs
# Write-Host (ConvertTo-Json -InputObject $LambdaInput -Compress -Depth 5)
# https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html
# https://medium.com/wehkamp-techblog/activedirectory-automation-with-aws-8fbaad3221fc
# https://docs.aws.amazon.com/lambda/latest/dg/powershell-package.html
# http://beta.awsdocs.com/scripts/powershell/windows_domainjoin/

<#
    Expected environment variables:
    AD_CREDENTIAL_SECRET_PATH - Secrets manager key to AD Secret (note this may change, as it may be needed per domain)
    ACTIVE_DIRECTORY_SERVER - the FQDN of the AD server to hit against (note this may change, as it may be needed per domain)
    EVENT_BRIDGE_INTERVAL - Defined interval in minutes on which the event bridge firing the lambda runs.  This is used for scheduling.
            For instance, if Duration is 4 hours, and it is currently 1/19/2022 8:31:06 AM, we want to disable this membership at
            about 1/19/2022 12:31:06 PM, but the lambda only triggers every X minutes.  If X is 15, and it runs at 12:15, 12:30, 12:45
            we wait until 12:45, the closest interval after the target time.  So we set our end date to current time + 4 hours + 15 minutes,
            rounding to the closest 15.
    SQS_QUEUE_NAME - Name of the SQS queue to forward messages for removal process  ** either this or DYNAMO_DB_TABLE_NAME
    DYNAMO_DB_TABLE_NAME - Name of DDB table that will act as the removal queue     ** either this or SQS_QUEUE_NAME
    SNS_TOPIC_NAME - Name of the SNS topic to notify when this lambda is executed
#>

$ADCredentialSecret = Get-SECSecretValue -SecretId $ENV:AD_CREDENTIAL_SECRET_PATH
$SecretString = $ADCredentialSecret.SecretString | ConvertFrom-Json
# Set PS credentials
$Credential = New-Object System.Management.Automation.PSCredential($SecretString.Username,$SecretString.Password)
$AccountId = $LambdaContext.InvokedFunctionArn.Split(":")[4]
$Region = $LambdaContext.InvokedFunctionArn.Split(":")[3]

foreach ($message in $LambdaInput.Records)
{
    # TODO: Add logic to handle each SQS Message
    Write-Host $message.body
    Write-Host $message.messageAttributes

    $MessageBodyObject = $message.Body | ConvertFrom-Json
    $Username = $MessageBodyObject.Username
    $DurationHours = $MessageBodyObject.DurationHours

    $Now = [datetime]::UtcNow
    $EndAdjustment = $Now.AddMinutes($ENV:EVENT_BRIDGE_INTERVAL)

    $EndTimeDate = $Now.AddHours($DurationHours) #.ToString()
    $PartitionKeyTime = $EndAdjustment.AddHours($DurationHours).AddMinutes(-$MinuteAdjustment).ToString("yyyy-MM-ddTHH:mmZ")
    $EndTimeEpoch = Get-Date -Date ($Now.AddHours($DurationHours).ToString()) -UFormat %s

    $ADParams = @{
        Server = $ENV:ACTIVE_DIRECTORY_SERVER
        Credential = $Credential
    }

    $UserObj = Get-AdUser $Username @ADParams
    $Group = Get-ADGroup "Domain Admins" @ADParams
    $Group | Add-ADGroupMember -Members $UserObj @ADParams

    Write-Host $DurationHours
    $UserObj | Get-ADPrincipalGroupMembership @ADParams | Select-Object -ExpandProperty Name | Write-Host

    # Submit SQS message to do the removal later:
    if ($ENV:SQS_QUEUE_NAME) {
        $UsernameAttributeValue = New-Object Amazon.SQS.Model.MessageAttributeValue
        $UsernameAttributeValue.DataType = "String"
        $UsernameAttributeValue.StringValue = $Username

        $RemovalTimeAttributeValue = New-Object Amazon.SQS.Model.MessageAttributeValue
        $RemovalTimeAttributeValue.DataType = "Number"
        $RemovalTimeAttributeValue.StringValue = $EndTimeEpoch

        $messageAttributes = New-Object System.Collections.Hashtable
        $messageAttributes.Add("Username", $UsernameAttributeValue)
        $messageAttributes.Add("RemovalTime", $RemovalTimeAttributeValue)

        $TARGET_SQS_ARN = 'arn:aws:sqs:{0}:{1}:{2}' -f $Region, $AccountId, $ENV:SQS_QUEUE_NAME
        $QueueUri = "https://sqs.{0}.amazonaws.com/{1}/{2}" -f $Region, $AccountId, $ENV:SQS_QUEUE_NAME
        Write-Host "SQS Queue Arn: $TARGET_SQS_ARN"
        Write-Host "SQS Uri: $QueueUri"
        Send-SQSMessage -DelayInSeconds 900 -MessageAttributes $messageAttributes -MessageBody "User $Username has been elevated to Domain Admin and set to expire in $DurationHours hours." -QueueUrl $QueueUri
    }
    
    # Or, write to Dynamo DB
    if ( $ENV:DYNAMO_DB_TABLE_NAME ) {
        $regionEndpoint = [Amazon.RegionEndPoint]::GetBySystemName($Region)
        $dbClient = New-Object Amazon.DynamoDBv2.AmazonDynamoDBClient($regionEndpoint)
        $req = New-Object Amazon.DynamoDBv2.Model.PutItemRequest
        $req.TableName = $ENV:DYNAMO_DB_TABLE_NAME

        $req.Item = New-Object 'system.collections.generic.dictionary[string,Amazon.DynamoDBv2.Model.AttributeValue]'

        $PKString = "j#{0}" -f $PartitionKeyTime
        $PKObj = New-Object Amazon.DynamoDBv2.Model.AttributeValue
        $PKObj.S = $PKString
        $req.Item.Add('PK', $PKObj)

        $SKString = "{0}#{1}" -f $EndTimeDate, $message.messageId
        $SKObj = New-Object Amazon.DynamoDBv2.Model.AttributeValue
        $SKObj.S = $SKString
        $req.Item.Add("SK", $SKObj)
        
        $DataStr = @{
            Username = $Username
            RequestReceived = $Now.ToString("yyyy-MM-ddTHH:mmZ")
            DurationHours = $DurationHours
            Action = "Remove-Domain-Admin"
        } | ConvertTo-Json

        $dataObj = New-Object Amazon.DynamoDBv2.Model.AttributeValue
        $dataObj.S = $DataStr
        $req.Item.Add("data", $dataObj)

        $dataObj = New-Object Amazon.DynamoDBv2.Model.AttributeValue
        $dataObj.S = "job-reminder"
        $req.Item.Add("item_type", $dataObj)

        $sqsObj = New-Object Amazon.DynamoDBv2.Model.AttributeValue
        $sqsObj.S = $message.body
        $req.Item.Add("item_trigger_details", $sqsObj)

        $dbClient.PutItem($req)
    }

    # Notify TechOps via SNS
    if ($ENV:SNS_TOPIC_NAME) {
        # $ENV:SNS_TOPIC_ARN = 'arn:aws:sns:us-west-2:123456789012:myTopic'
        $SNS_TOPIC_ARN = 'arn:aws:sns:{0}:{1}:{2}' -f $Region, $AccountId, $ENV:SNS_TOPIC_NAME
        Write-Host "SNS Topic ARN: $SNS_TOPIC_ARN"
        Publish-SNSMessage -TopicArn $SNS_TOPIC_ARN -Message $Message
    }
    $Message = "User $Username has been elevated to Domain Admin and it is set to expire in $DurationHours hours"
    Write-Host $Message
}