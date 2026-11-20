# Usage: ./deploy-runtime.sh <image-tag>
IMAGE_TAG="$1"
if [ -z "${IMAGE_TAG}" ]; then
  echo "Usage: $0 <image-tag>" >&2
  exit 1
fi

export ACCOUNT_ID="${AWS_ACCOUNT_ID}"
export REPO_REGION="eu-west-1"
export REPO_NAME="llm-runtime"
export RUNTIME_NAME="llm-runtime"
export RUNTIME_VERSION="v${IMAGE_TAG}"

aws lambda-core create-runtime --name ${RUNTIME_NAME} \
--description "Customer-managed runtime llm" \
--license-info "None" \
> /dev/null

RUNTIME_ARN=$(aws lambda-core get-runtime --runtime-name ${RUNTIME_NAME} \
--query 'Arn' \
--output text)

aws lambda-core create-runtime-version \
--runtime-name ${RUNTIME_NAME} \
--image-uri ${ACCOUNT_ID}.dkr.ecr.${REPO_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG} \
--name ${RUNTIME_VERSION} \
> /dev/null

aws lambda-core get-runtime-version --runtime-name ${RUNTIME_NAME} \
--name ${RUNTIME_VERSION} \
> /dev/null

aws lambda-core wait runtime-version-active --runtime-name ${RUNTIME_NAME} --name ${RUNTIME_VERSION} \
> /dev/null

echo "RUNTIME_ARN: ${RUNTIME_ARN}"
echo "RUNTIME_VERSION: ${RUNTIME_VERSION}"
