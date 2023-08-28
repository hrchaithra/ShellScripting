#!/bin/bash
################################
# Author: chaithra
# Version: v1
#
#Script to invoke S3-Event as a notification using S3,Lamdba and SNS
#
# 
################################

set -x

# Store Account ID in a variable
aws_account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Print the account ID from variable
echo "AWS account Id is $aws_account_id"

# Set AWS region and other info
aws_region="us-east-1"
bucket_name="mynew-shellscript-bucket"
lambda_func_name="s3-lamdba-func"
role_name="s3-lambda-sns"
email_addr="tacapi2054@trazeco.com"

# Create an IAM role
role=$(aws iam create-role --role-name s3-lambda-sns --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "s3.amazonaws.com",
          "sns.amazonaws.com"                       
         ]
       }
     }]
  }')

# Extract role arn from the json response and store it in variable
role_arn=$(echo "$role" | jq -r '.Role.Arn')

# Display Role ARN
echo "Role ARN : $role_arn"

# Attaching permissions to the Role
aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess
aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess

# Creating S3 bucket and assigning it to a variable
bucket=$(aws s3api create-bucket --bucket "$bucket_name" --region "$aws_region")

# Display the bucket created info
echo "Bucket $bucket created successfully"

# Upload file to bucket
aws s3 cp ./examplefile.txt s3://"$bucket_name"/examplefile.txt

# Creating zip file to upload lambda func
zip -r s3-lambda-function.zip ./s3-lamdba-function

sleep 5

# Create lambda function
aws lambda create-function \
  --region "$aws_region" \
  --function-name $lamdba_func_name \
  --runtime "python3.8" \
  --handler "s3-lambda-function/s3-lambda-function.lambda_handler" \
  --memory-size 128 \
  --timeout 30 \
  --role "arn:aws:iam::$aws_account_id:role/$role_name" \
  --zip-file "fileb://./s3-lambda-function.zip"

# Add permission to s3 to invoke lambda func
aws lambda add-permission \
  --function-name "$lambda_func_name" \
  --statement-id "s3-lambda-sns" \
  --action "lambda:InvokeFunction" \
  --principal s3.amazonaws.com \
  --source-arn "arn:aws:s3:::$bucket_name"

# Create event trigger for lambda
aws s3api put-bucket-notification-configuration \
  --region "$aws_region" \
  --bucket "$bucket_name" \
  --notification-configuration '{
      "LambdaFunctionConfigurations": [{
        "LambdaFunctionArn": "arn:aws:lambda:"$aws_region":$aws_account_id:function:$lambda_func_name",
        "Events": ["s3:ObjectCreated:*"]
      }]
  }'

# Create an SNS topic
topic_arn=$(aws sns create-topic --name s3-lambda-sns --output json | jq -r '.TopicArn')

# Print the TopicArn
echo "SNS Topic ARN $topic_arn"

# Add SNS permission to Lambda
aws sns subscribe \
  --region us-east-1 \
  --topic-arn "$topic_arn" \
  --protocol email \
  --notification-endpoint "$email_addr" 

# Publish SNS
aws sns publish \
--region us-east-1 \
--topic-arn "$topic_arn" \
--subject "A new object created in s3 bucket" \
--message "Hello, Event Trigger successful"






