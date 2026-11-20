#!/bin/bash
echo "starting ollama"

ollama serve &

if [ -n "${MODEL_BUCKET}" ]; then
  if ! NODE_PATH=/var/runtime/node_modules node /usr/local/lib/fetch-model.cjs; then
    echo "wrapper: model download failed, aborting init" >&2
    exit 1
  fi
else
  echo "wrapper: MODEL_BUCKET not set, skipping model download" >&2
fi

for _ in $(seq 1 50); do
  curl -fs "http://${OLLAMA_HOST}/api/version" >/dev/null && break
  sleep 0.1
done

if ! curl -fs "http://${OLLAMA_HOST}/api/version" >/dev/null; then
  echo "wrapper: ollama did not become ready on ${OLLAMA_HOST}" >&2
fi

exec "$@"
