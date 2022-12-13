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
TESTFLAGS :=
LDFLAGS := -w -s -X "main.Version=$(VERSION)" -X "main.Revision=$(REVISION)" -extldflags "-static"
GOFLAGS :=
CGO_ENABLED ?= 0

SRC := $(shell find . -type f -name '*.go' -print) go.mod go.sum
VERSION := $(shell cat VERSION)
REVISION := $(shell git rev-parse --short HEAD)

# ---------------------------------------------
# build

.PHONY: build
build: $(BINDIR)/$(BINNAME)

$(BINDIR)/$(BINNAME): $(SRC)
	CGO_ENABLED=$(CGO_ENABLED) go build $(GOFLAGS) -trimpath -tags '$(TAGS)' -ldflags '$(LDFLAGS)' -o '$(BINDIR)'/$(BINNAME) ./cmd/server

.PHONY: lint
lint: $(LINTER)
	$(LINTER) run ./...

# ---------------------------------------------
# protobuf gen
.PHONY: gen
gen: $(BUFBIN)
	$(BUFBIN) generate

# ---------------------------------------------
# format
.PHONY: format
format: $(GOIMPORTS)
	go list -f '{{.Dir}}' ./... | xargs $(GOIMPORTS) -w -local examples/grpc-greeter

# ---------------------------------------------
.PHONY: clean
clean:
	@rm -rf '$(BINDIR)'

# ---------------------------------------------
# dependencies

$(GOIMPORTS):
	(cd /; go install golang.org/x/tools/cmd/goimports@latest)

$(BUFBIN):
	(cd /; go install github.com/bufbuild/connect-go/cmd/protoc-gen-connect-go@latest)

$(LINTER):
	(cd /; go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.50.1)
