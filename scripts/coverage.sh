#!/usr/bin/env bash

set -euo pipefail

covermode=${COVERMODE:-atomic}
coverdir=${REPORTDIR:-$(mktemp -d /tmp/coverage.XXXXXXXXXX)}
profile="${coverdir}/cover.out"
report="${coverdir}/test.json"

go test -cover -coverprofile="${profile}" -covermode="$covermode" ./... -json >${report}
go tool cover -func "${profile}"

case "${1-}" in
  --html)
    go tool cover -html "${profile}"
    ;;
esac
