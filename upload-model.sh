MODEL="$1"
if [ -z "${MODEL}" ] || [ -z "${MODEL_BUCKET}" ]; then
  echo "Usage: MODEL_BUCKET=<bucket> $0 <ollama-model>" >&2
  exit 1
fi
set -e

export REPO_REGION="eu-west-1"
WORK_DIR="$(mktemp -d)"
CONTAINER="ollama-pull-$$"
trap 'docker rm -f ${CONTAINER} >/dev/null 2>&1; rm -rf "${WORK_DIR}"' EXIT

if ! aws s3api head-bucket --bucket "${MODEL_BUCKET}" 2>/dev/null; then
  aws s3api create-bucket --bucket "${MODEL_BUCKET}" --region ${REPO_REGION} \
  --create-bucket-configuration LocationConstraint=${REPO_REGION} \
  > /dev/null
fi

docker run -d --name ${CONTAINER} -v "${WORK_DIR}:/root/.ollama/models" \
  ollama/ollama > /dev/null
until docker exec ${CONTAINER} ollama list > /dev/null 2>&1; do sleep 0.5; done
docker exec ${CONTAINER} ollama pull "${MODEL}"
docker rm -f ${CONTAINER} > /dev/null

aws s3 sync --delete "${WORK_DIR}/" "s3://${MODEL_BUCKET}/models/${MODEL}/" \
  --region ${REPO_REGION}
