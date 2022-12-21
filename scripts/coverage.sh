#!/usr/bin/env bash

set -euo pipefail

covermode=${COVERMODE:-atomic}
coverdir=${REPORTDIR:-$(mktemp -d /tmp/coverage.XXXXXXXXXX)}
profile="${coverdir}/cover.out"
report="${coverdir}/test"

install_tools() {
  pushd /
  hash gocover-cobertura 2>/dev/null || go install github.com/boumenot/gocover-cobertura@latest
  hash go-junit-report 2>/dev/null || go install github.com/jstemmer/go-junit-report/v2@latest
  popd
}

install_tools

set +e
go test -cover -coverprofile="${profile}" -covermode="$covermode" ./... -json >${report}.json
ret=$?
set -e

go tool cover -func "${profile}"
go-junit-report -in ${report}.json -parser gojson -out ${report}.xml

case "${1-}" in
  --html)
    go tool cover -html "${profile}"
    ;;
  --cobertura)
    gocover-cobertura < ${profile} > ${coverdir}/coverage.xml
    ;;
esac

exit $ret
