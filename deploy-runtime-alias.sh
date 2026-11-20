# Usage: ./deploy-runtime-alias.sh <runtime-version>
RUNTIME_VERSION="$1"
if [ -z "${RUNTIME_VERSION}" ]; then
  echo "Usage: $0 <runtime-version>" >&2
  exit 1
fi

export RUNTIME_NAME="llm-runtime-6"
export RUNTIME_ALIAS="production"

aws lambda-core get-runtime-version --runtime-name ${RUNTIME_NAME} \
--name ${RUNTIME_VERSION} \
> /dev/null

if aws lambda-core get-runtime-alias \
  --runtime-name ${RUNTIME_NAME} \
  --name ${RUNTIME_ALIAS} \
  > /dev/null 2>&1; then
  echo "Updating alias ${RUNTIME_ALIAS} -> ${RUNTIME_VERSION}"
  aws lambda-core update-runtime-alias \
  --runtime-name ${RUNTIME_NAME} \
  --name ${RUNTIME_ALIAS} \
  --runtime-version ${RUNTIME_VERSION} \
  > /dev/null
else
  echo "Creating alias ${RUNTIME_ALIAS} -> ${RUNTIME_VERSION}"
  aws lambda-core create-runtime-alias \
  --runtime-name ${RUNTIME_NAME} \
  --name ${RUNTIME_ALIAS} \
  --runtime-version ${RUNTIME_VERSION} \
  > /dev/null
fi

aws lambda-core wait runtime-alias-active --runtime-name ${RUNTIME_NAME} --name ${RUNTIME_ALIAS} \
> /dev/null
