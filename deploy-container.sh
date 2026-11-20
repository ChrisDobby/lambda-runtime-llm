DOCKERFILE="$1"
IMAGE_TAG="$2"
if [ -z "${DOCKERFILE}" ] || [ -z "${IMAGE_TAG}" ]; then
  echo "Usage: $0 <dockerfile> <image-tag>" >&2
  exit 1
fi

export ACCOUNT_ID="${AWS_ACCOUNT_ID}"
export REPO_REGION="eu-west-1"
export REPO_NAME="llm-runtime"

aws ecr create-repository --repository-name ${REPO_NAME} --region ${REPO_REGION} > /dev/null

aws ecr set-repository-policy \
--repository-name ${REPO_NAME} \
--policy-text '{
"Version": "2012-10-17",
"Statement": [
{
"Sid": "LambdaReadAccess",
"Effect": "Allow",
"Principal": {
"Service": "lambda.amazonaws.com"
},
"Action": [
"ecr:BatchGetImage",
"ecr:DescribeImages",
"ecr:GetDownloadUrlForLayer"
]
}
]
}' \
--region ${REPO_REGION} \
> /dev/null

aws ecr get-login-password --region ${REPO_REGION} | docker login \
--username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REPO_REGION}.amazonaws.com \
> /dev/null

docker build --file "${DOCKERFILE}" --tag ${REPO_NAME}:${IMAGE_TAG} .

docker tag ${REPO_NAME}:${IMAGE_TAG} \
${ACCOUNT_ID}.dkr.ecr.${REPO_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}

docker push ${ACCOUNT_ID}.dkr.ecr.${REPO_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}
