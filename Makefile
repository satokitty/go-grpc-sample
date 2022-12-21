BINDIR := $(CURDIR)/bin
BINNAME ?= server

GOBIN = $(shell go env GOBIN)
ifeq ($(GOBIN),)
GOBIN = $(shell go env GOPATH)/bin
endif
GOIMPORTS = $(GOBIN)/goimports
BUFBIN = $(GOBIN)/buf
LINTER = $(GOBIN)/golangci-lint

# go option
PKG := ./...
TAGS :=
TESTS := .
TESTFLAGS := -race -v
LDFLAGS := -w -s
EXT_LDFLAGS := -extldflags "-static"
GOFLAGS :=
CGO_ENABLED ?= 0

REPORTDIR := $(CURDIR)/reports

GIT_COMMIT = $(shell git rev-parse HEAD)
GIT_SHA = $(shell git rev-parse --short HEAD)
GIT_TAG = $(shell git describe --tags --abbrev=0 --exact-match 2>/dev/null)

SRC := $(shell find . -type f -name '*.go' -print) go.mod go.sum
ifdef VERSION
	BINARY_VERSION
endif
BINARY_VERSION ?= ${GIT_TAG}

# Only set Version if building a tag or VERSION is set
ifneq ($(BINARY_VERSION),)
	LDFLAGS += -X "main.Version=$(BINARY_VERSION)"
endif
LDFLAGS += -X "main.Revision=$(GIT_SHA)"
LDFLAGS += $(EXT_LDFLAGS)

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
# Dockerfile
.PHONY: lint-dockerfile
lint-dockerfile:
	@ USE_DOCKER=true ./scripts/lint-dockerfile.sh

# ---------------------------------------------
# dependencies

$(GOIMPORTS):
	(cd /; go install golang.org/x/tools/cmd/goimports@latest)

$(BUFBIN):
	(cd /; go install github.com/bufbuild/connect-go/cmd/protoc-gen-connect-go@latest)

$(LINTER):
	(cd /; go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.50.1)
