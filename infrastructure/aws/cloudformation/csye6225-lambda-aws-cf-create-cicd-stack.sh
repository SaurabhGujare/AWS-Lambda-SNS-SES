#!/usr/bin/env bash

echo "Write the stack-name"
read Stack_Name

if [ -z Stack_Name ]
  then
    echo "No STACK_NAME argument supplied"
    exit 1
fi
check1=$(aws cloudformation describe-stacks --stack-name $Stack_Name)


error=$?

if [ $error -eq 0 ]; then

echo "Stack with same name already exists, please enter a different name"
echo "Terminating script, pls re-run with a new stack name"
exit 1

fi

echo "This error confirms that the stack name we gave was unique"

BucketName=$(aws s3api list-buckets | jq -r '.Buckets[] | select(.Name | startswith("code-deploy")).Name')
WebAppBucket=$(aws s3api list-buckets | jq -r '.Buckets[] | select(.Name | startswith("csye6225")).Name')


echo "Creating stack..."
STACK_ID=$(aws cloudformation create-stack \
  --stack-name $Stack_Name \
  --template-body file://csye6225-lambda-aws-cf-cicd.json \
  --parameters ParameterKey="BucketName",ParameterValue=${BucketName} ParameterKey="WebAppBucket",ParameterValue=${WebAppBucket} --capabilities CAPABILITY_NAMED_IAM)
echo $STACK_ID
echo "Waiting on ${STACK_ID} create completion..."
aws cloudformation wait stack-create-complete --stack-name ${Stack_Name}
aws cloudformation describe-stacks --stack-name ${Stack_Name} | jq .Stacks[0].Outputs