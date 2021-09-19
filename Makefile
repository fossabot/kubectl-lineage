SHELL:=/bin/bash

GO_VERSION = "1.16"
GOLANGCI_LINT_VERSION = "1.41.1"
GORELEASER_VERSION = "0.179.0"

export BUILD_DATE = $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
export GIT_COMMIT = $(shell git rev-parse HEAD)
export GIT_TREE_STATE = $(shell if [ -z "`git status --porcelain`" ]; then echo "clean" ; else echo "dirty"; fi)
export GIT_VERSION = $(shell git describe --tags --match "v*.*.*")
export GIT_VERSION_MAJOR = $(shell echo ${GIT_VERSION} | cut -d 'v' -f 2 | cut -d "." -f 1)
export GIT_VERSION_MINOR = $(shell echo ${GIT_VERSION} | cut -d 'v' -f 2 | cut -d "." -f 2)
export CGO_ENABLED = 1

REPO = $(shell go list -m)
GO_BUILD_ARGS = \
  -gcflags "all=-trimpath=$(shell dirname $(shell pwd))" \
  -asmflags "all=-trimpath=$(shell dirname $(shell pwd))" \
  -ldflags " \
    -s \
    -w \
    -X '$(REPO)/internal/version.buildDate=$(BUILD_DATE)' \
    -X '$(REPO)/internal/version.gitCommit=$(GIT_COMMIT)' \
    -X '$(REPO)/internal/version.gitTreeState=$(GIT_TREE_STATE)' \
    -X '$(REPO)/internal/version.gitVersion=$(GIT_VERSION)' \
    -X '$(REPO)/internal/version.gitVersionMajor=$(GIT_VERSION_MAJOR)' \
    -X '$(REPO)/internal/version.gitVersionMinor=$(GIT_VERSION_MINOR)' \
  " \

.PHONY: all
all: install

.PHONY: build
build:
	go build $(GO_BUILD_ARGS) -o bin/kubectl-lineage ./cmd/kubectl-lineage

.PHONY: test
test:
	go test ./...

.PHONY: install
install: build
	install bin/kubectl-lineage $(shell go env GOPATH)/bin

.PHONY: lint
lint:
	source ./scripts/fetch.sh; fetch golangci-lint $(GOLANGCI_LINT_VERSION) && ./bin/golangci-lint run

.PHONY: release
RELEASE_ARGS?=release --rm-dist
release:
	source ./scripts/fetch.sh; fetch goreleaser $(GORELEASER_VERSION) && ./bin/goreleaser $(RELEASE_ARGS)
