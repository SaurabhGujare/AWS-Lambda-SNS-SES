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
function=resetPassword
domainname=$(aws route53 list-hosted-zones --query 'HostedZones[0].Name' --output text)
domain_name=${domainname%.}
BucketName=$(aws s3api list-buckets | jq -r '.Buckets[] | select(.Name | startswith("code-deploy")).Name')
WebAppBucket=$(aws s3api list-buckets | jq -r '.Buckets[] | select(.Name | startswith("csye6225")).Name')
Lambda_IAMRole=$(aws iam get-role --role-name lambdaIAMRole --query Role.Arn --output text)


echo "Creating stack..."
STACK_ID=$(aws cloudformation create-stack \
  --stack-name ${Stack_Name} \
  --template-body file://csye6225-aws-cf-create-lambda.json \
  --parameters ParameterKey="myBucketName",ParameterValue=${BucketName} ParameterKey="domainName",ParameterValue=${domain_name} ParameterKey="functionName",ParameterValue=${function} ParameterKey="lambdaIAMRole",ParameterValue=${Lambda_IAMRole} \
  --capabilities CAPABILITY_NAMED_IAM --capabilities CAPABILITY_IAM | jq -r .StackId \
  )
echo $STACK_ID
echo "Waiting on ${STACK_ID} create completion..."
aws cloudformation wait stack-create-complete --stack-name ${Stack_Name}
aws cloudformation describe-stacks --stack-name ${Stack_Name} | jq .Stacks[0].Outputs