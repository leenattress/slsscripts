#!/bin/bash

command -v aws >/dev/null 2>&1 || { echo >&2 "We require aws but it's not installed.  Aborting."; exit 1; }

if (( $# != 1 )); then
    >&2 echo "Error: You pass only one parameter into this script, its your mfa code from your device."
fi

TOKEN_CODE=$1    # mfa code
MFA_PROFILE='mfa'

echo "Enabling MFA Security for IAM Profile: AWSPROFILE"

# min --duration-seconds is 900 (15 mins)
AWS_RESPONSE=$(aws sts get-session-token --serial-number IAMARN --token-code $TOKEN_CODE --profile AWSPROFILE --duration-seconds 3600 --output text)
if [ "$AWS_RESPONSE" = "" ]
then
  echo "Something went wrong getting your MFA credentials."
  exit 1
fi

AWS_ACCESS_KEY_ID=$(echo $AWS_RESPONSE | awk {'print $2'})
AWS_SECRET_ACCESS_KEY=$(echo $AWS_RESPONSE | awk {'print $4'})
AWS_SESSION_TOKEN=$(echo $AWS_RESPONSE | awk {'print $5'})

aws configure --profile $MFA_PROFILE set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure --profile $MFA_PROFILE set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure --profile $MFA_PROFILE set aws_session_token $AWS_SESSION_TOKEN

echo "MFA enabled!"
echo "You can now: slsinfo, slsdeploy or slsoffline inside your serverless folder."
