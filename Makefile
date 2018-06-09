.PHONY: all build build-alpine release clean test help default install-hooks clean-hooks run-hooks

BIN_NAME=gocrawler

VERSION := $(shell grep "const Version " version.go | sed -E 's/.*"(.+)"$$/\1/')
GIT_COMMIT=$(shell git rev-parse HEAD)
GIT_DIRTY=$(shell test -n "`git status --porcelain`" && echo "+CHANGES" || true)
IMAGE_NAME := "paulwilljones/gocrawler"

default: help

help:				## Show this help.
		@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

build:				## Compile the project.
	@echo "building ${BIN_NAME} ${VERSION}"
	@echo "GOPATH=${GOPATH}"
	go build -ldflags "-X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY} -X main.VersionPrerelease=DEV" -o bin/${BIN_NAME}

get-deps:			## Runs dep ensure.
	dep ensure

build-alpine:			## Compile optimized for alpine linux.
	@echo "building ${BIN_NAME} ${VERSION}"
	@echo "GOPATH=${GOPATH}"
	go build -ldflags '-w -linkmode external -extldflags "-static" -X main.GitCommit=${GIT_COMMIT}${GIT_DIRTY} -X main.VersionPrerelease=VersionPrerelease=RC' -o bin/${BIN_NAME}

package:			## Build final docker image with just the go binary inside.
	@echo "building image ${BIN_NAME} ${VERSION} $(GIT_COMMIT)"
	docker build --build-arg VERSION=${VERSION} --build-arg GIT_COMMIT=$(GIT_COMMIT) -t $(IMAGE_NAME):local .

tag:				## Tag image created by package with latest, git commit and version.
	@echo "Tagging: latest ${VERSION} $(GIT_COMMIT)"
	docker tag $(IMAGE_NAME):local $(IMAGE_NAME):$(GIT_COMMIT)
	docker tag $(IMAGE_NAME):local $(IMAGE_NAME):${VERSION}
	docker tag $(IMAGE_NAME):local $(IMAGE_NAME):latest

push: tag			## Push tagged images to registry.
	@echo "Pushing docker image to registry: latest ${VERSION} $(GIT_COMMIT)"
	docker push $(IMAGE_NAME):$(GIT_COMMIT)
	docker push $(IMAGE_NAME):${VERSION}
	docker push $(IMAGE_NAME):latest

release:
	docker tag paulwilljones/gocrawler:local quay.io/paulwilljones/gocrawler:master
	docker push quay.io/paulwilljones/gocrawler:master

clean:				## Clean the directory tree.
	@test ! -e bin/${BIN_NAME} || rm bin/${BIN_NAME}

test:				## Run tests on a compiled project.
	go test $(glide nv)

install-hooks:			## Install pre-commit hooks.
	pip install -r requirements.txt
	pip install --upgrade pre-commit
	pre-commit install --install-hooks
	pre-commit autoupdate

clean-hooks:			## Clean the repo of pre-commit hooks.
	pre-commit clean
	pre-commit uninstall

run-hooks: install-hooks	## Run pre-commit hooks locally.
	pre-commit run --all-files
