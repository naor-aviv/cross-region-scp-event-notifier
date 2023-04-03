import json
import boto3
import logging
import os

s3 = boto3.client('s3')
ses = boto3.client("ses")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
def lambda_handler(event, context):
    # Get error details
    error_code = event['detail']['errorCode']
    error_source = event['source']
    
    # Check for vaild source mail
    try:
        source_mail = os.environ['SES_SOURCE']
    except KeyError as e:
        logger.error(f"Environment variable 'SES_SOURCE' not set: {e}")
        return

    # Extract the error message
    try:
        error_message = event['detail']['errorMessage']
        error_action = error_message.split(": ")[2].split(" ")[0]
        resource_arn = error_message.split(": ")[3].split(" ")[0]
    except:
        error_action = event['detail']['eventName']
        resource_arn = None
    # Extract the user ID
    try:
        error_message_mail = event['detail']['userIdentity']['principalId'].split(":")[1]
    except Exception as e:
        error_message_mail = event['detail']['userIdentity']['arn'].split("/")[2]
    # Get count from S3 file
    try:
        bucket_name = os.environ['BUCKET_NAME']
    except KeyError as e:
        logger.error(f"Environment variable 'BUCKET_NAME' not set: {e}")
        return
    try:
        s3_object = s3.get_object(Bucket=bucket_name, Key='count.txt')
        count = int(s3_object['Body'].read().decode("utf-8"))
    except Exception as e:
        logger.error(f"Error getting count from S3: {e}")
        count = 0
        
    # Increment count and write to S3 file
    count += 1
    try:
        s3.put_object(Bucket=bucket_name, Key='count.txt', Body=str(count).encode())
    except Exception as e:
        logger.error(f"Error writing to S3: {e}")
    
    # Update for too much LAMBDA requests
    if count >= 100:
        warning_message = {'Subject': {'Data': "Lambda limit"}, 'Body': {'Html': {'Data': f""" <b>WARNING!</b> Your Lambda function ran {count} time this month."""}}}
        warning_destination = {'ToAddresses': ["naor@terasky.com"]}
        warning_response = ses.send_email(Source=source_mail, Destination=warning_destination, Message=warning_message)
    
    # Prepare email body
    if 'errorMessage' not in event['detail']:
        mail_body = f"""Failed to perform action "<b>{error_action}</b>" on resource "<b>{error_source}</b>" 
                        with explicit deny in service control policy.<br>
                        Error code: "<b>{error_code}</b>".<br>
                        Count: <b>{count}</b>."""
    else:
        mail_body = f"""Failed to perform action "<b>{error_action}</b>" on resource "<b>{error_source}</b>" 
                        with explicit deny in service control policy.<br>
                        Resource ARN: "<b>{resource_arn}</b>".<br>
                        Error code: "<b>{error_code}</b>".<br>
                        Count: <b>{count}</b>."""
                    
    # Send email
    subject = 'Denied action by SCP'
    body = mail_body
    destination = {'ToAddresses': [error_message_mail]}
    message = {'Subject': {'Data': subject}, 'Body': {'Html': {'Data': body}}}

    response = ses.send_email(Source=source_mail, Destination=destination, Message=message)
    
    print(f"Date: {response['ResponseMetadata']['HTTPHeaders']['date']}\nResponse Code: {response['ResponseMetadata']['HTTPStatusCode']}")
