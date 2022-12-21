BINDIR := $(CURDIR)/bin
BINNAME ?= server

GOBIN = $(shell go env GOBIN)
ifeq ($(GOBIN),)
GOBIN = $(shell go env GOPATH)/bin
endif
GOIMPORTS = $(GOBIN)/goimports
BUFBIN = $(GOBIN)/buf
LINTER = $(GOBIN)/golangci-lint


REPORTDIR := $(CURDIR)/reports

# go option
PKG := ./...
TAGS :=
TESTS := .
TESTFLAGS := -race -v
LDFLAGS := -w -s -X "main.Version=$(VERSION)" -X "main.Revision=$(REVISION)" -extldflags "-static"
GOFLAGS :=
CGO_ENABLED ?= 0

SRC := $(shell find . -type f -name '*.go' -print) go.mod go.sum
VERSION := $(shell cat VERSION)
REVISION := $(shell git rev-parse --short HEAD)

# ---------------------------------------------
# all
.PHONY: all
all: clean format lint build coverage

# ---------------------------------------------
# build
.PHONY: build
build: $(BINDIR)/$(BINNAME)

$(BINDIR)/$(BINNAME): $(SRC)
	CGO_ENABLED=$(CGO_ENABLED) go build $(GOFLAGS) -trimpath -tags '$(TAGS)' -ldflags '$(LDFLAGS)' -o '$(BINDIR)'/$(BINNAME) ./cmd/server

# ---------------------------------------------
# test

.PHONY: test
test: lint
test: build
test: test-unit

.PHONY: test-unit
test-unit:
	@echo
	@echo "==> Running unit tests..."
	go test $(GOFLAGS) -run $(TESTS) $(PKG) $(TESTFLAGS)

.PHONY: coverage
coverage:
	@echo
	@echo "==> Running unit tests with coverage..."
	@ rm -rf '$(REPORTDIR)'
	@ mkdir '$(REPORTDIR)'
	@ REPORTDIR=$(REPORTDIR) ./scripts/coverage.sh --cobertura

.PHONY: lint
lint: $(LINTER)
	$(LINTER) run

# ---------------------------------------------
# protobuf gen
.PHONY: gen
gen: $(BUFBIN)
	$(BUFBIN) generate

# ---------------------------------------------
# format
.PHONY: format
format: $(GOIMPORTS)
	go list -f '{{.Dir}}' ./... | grep -v '/gen/' | xargs $(GOIMPORTS) -w -local examples/grpc-greeter

# ---------------------------------------------
.PHONY: clean
clean:
	@rm -rf '$(BINDIR)'
	@rm -rf '$(REPORTDIR)'

# ---------------------------------------------
# dependencies

$(GOIMPORTS):
	(cd /; go install golang.org/x/tools/cmd/goimports@latest)

$(BUFBIN):
	(cd /; go install github.com/bufbuild/connect-go/cmd/protoc-gen-connect-go@latest)

$(LINTER):
	(cd /; go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.50.1)
