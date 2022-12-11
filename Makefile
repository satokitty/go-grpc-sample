BINDIR := $(CURDIR)/bin
BINNAME ?= server

GOBIN = $(shell go env GOBIN)
ifeq ($(GOBIN),)
GOBIN = $(shell go env GOPATH)/bin
endif
GOIMPORTS = $(GOBIN)/goimports

# go option
PKG := ./...
TAGS :=
TESTS := .
TESTFLAGS :=
LDFLAGS := -w -s
GOFLAGS :=
CGO_ENABLED ?= 0

SRC := $(shell find . -type f -name '*.go' -print) go.mod go.sum

# ---------------------------------------------
# build

.PHONY: build
build: $(BINDIR)/$(BINNAME)

$(BINDIR)/$(BINNAME): $(SRC)
	CGO_ENABLED=$(CGO_ENABLED) go build $(GOFLAGS) -trimpath -tags '$(TAGS)' -ldflags '$(LDFLAGS)' -o '$(BINDIR)'/$(BINNAME) ./cmd/server

# ---------------------------------------------
# format
.PHONY: format
format: $(GOIMPORTS)
	go list -f '{{.Dir}}' ./... | xargs $(GOIMPORTS) -w -local examples/grpc-greeter

# ---------------------------------------------
.PHONY: clean
clean:
	@rm -rf '$(BINDIR)'
