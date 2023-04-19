#!/usr/bin/env bash

CONTAINER=omg-template-service-1
GO_FILE=./cmd/template-service
GO_FILE_CMD=

if [[ "${DEBUG}" = "true" || "${DEBUG}" = "1" ]]; then
  echo "Debugging Enabled"
  set -x
  docker exec -ti ${CONTAINER} /workspace.sh dlv --accept-multiclient --api-version=2 --headless=true --listen=:40000 debug ${GO_FILE} -- ${GO_FILE_CMD}
  set +x
else
  set -x
  docker exec -ti ${CONTAINER} /workspace.sh go run ${GO_FILE} ${GO_FILE_CMD}
  set +x
fi
