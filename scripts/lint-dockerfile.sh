#!/usr/bin/env bash

set -x
set -euo pipefail

HADOLINT="hadolint - "
if [[ -v USE_DOCKER ]]; then
  HADOLINT="docker run --rm -i hadolint/hadolint"
fi
outputdir=${REPORTDIR:-$(mktemp -d /tmp/lint-dockerfile.XXXXXXXXXX)}

check_tools() {
  if [[ -v USE_DOCKER ]]; then
    if ! hash docker 2>/dev/null; then
      echo "'docker' command does not found."
      exit 1
    fi
  else
    if ! hash hadolint 2>/dev/null; then
      echo "'hadolint' command does not found."
      exit 1
    fi
  fi
}

check_tools

if [ ! -d $outputdir ]; then
  mkdir -p $outputdir
fi

case "${1---default}" in
  --gitlab)
    ${HADOLINT} -f gitlab_codeclimate < Dockerfile > $outputdir/hadolint-$(md5sum Dockerfile | cut -d" " -f1).json
    ;;
  --default)
    ${HADOLINT} < Dockerfile
    ;;
esac
