# Usage: MODEL_BUCKET=<bucket> ./deploy-test-function.sh <runtime-arn>
RUNTIME_ARN="$1"
if [ -z "${RUNTIME_ARN}" ] || [ -z "${MODEL_BUCKET}" ]; then
  echo "Usage: MODEL_BUCKET=<bucket> $0 <runtime-arn>" >&2
  exit 1
fi

export ACCOUNT_ID="${AWS_ACCOUNT_ID}"
export RUNTIME_ALIAS="production"
export FUNCTION_NAME="cmr-llm-test"

zip -j ./test.zip ./functions/test/src/index.mjs

aws iam create-role \
--role-name cmr-llm-execution-role \
--assume-role-policy-document '{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Principal": {
"Service": "lambda.amazonaws.com"
},
"Action": "sts:AssumeRole"
}
]
}'

aws iam attach-role-policy \
--role-name cmr-llm-execution-role \
--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
> /dev/null

aws iam put-role-policy \
--role-name cmr-llm-execution-role \
--policy-name model-bucket-read \
--policy-document "{
\"Version\": \"2012-10-17\",
\"Statement\": [
{
\"Effect\": \"Allow\",
\"Action\": \"s3:ListBucket\",
\"Resource\": \"arn:aws:s3:::${MODEL_BUCKET}\",
\"Condition\": {\"StringLike\": {\"s3:prefix\": \"models/*\"}}
},
{
\"Effect\": \"Allow\",
\"Action\": \"s3:GetObject\",
\"Resource\": \"arn:aws:s3:::${MODEL_BUCKET}/models/*\"
}
]
}"

sleep 10

aws lambda create-function \
--function-name ${FUNCTION_NAME} \
--runtime "custom" \
--runtime-config "{\"RuntimeArn\":\"${RUNTIME_ARN}\",\"RuntimeAlias\":\"${RUNTIME_ALIAS}\"}" \
--handler "index.handler" \
--timeout 300 \
--memory-size 4096 \
--ephemeral-storage '{"Size": 4096}' \
--environment "Variables={MODEL_BUCKET=${MODEL_BUCKET}}" \
--role "arn:aws:iam::${ACCOUNT_ID}:role/cmr-llm-execution-role" \
--zip-file fileb://./test.zip \
--architectures "arm64"
