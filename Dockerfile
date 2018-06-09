# Build Stage
FROM quay.io/paulwilljones/docker-alpine:gobuildimage AS build-stage

LABEL app="build-gocrawler"
LABEL REPO="https://github.com/paulwilljones/gocrawler"

ENV GOROOT=/usr/local/go \
    GOPATH=/gopath \
    GOBIN=/gopath/bin \
    PROJPATH=/gopath/src/github.com/paulwilljones/gocrawler

# Because of https://github.com/docker/docker/issues/14914
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin

ADD . /gopath/src/github.com/paulwilljones/gocrawler
WORKDIR /gopath/src/github.com/paulwilljones/gocrawler

RUN make build-alpine

# Final Stage
FROM quay.io/paulwilljones/docker-alpine:master

ARG GIT_COMMIT
ARG VERSION
LABEL NAME="gocrawler"
LABEL REPO="https://github.com/paulwilljones/gocrawler"
LABEL GIT_COMMIT=$GIT_COMMIT
LABEL VERSION=$VERSION

# Because of https://github.com/docker/docker/issues/14914
ENV PATH=$PATH:/opt/gocrawler/bin

WORKDIR /opt/gocrawler/bin

COPY --from=build-stage /gopath/src/github.com/paulwilljones/gocrawler/bin/gocrawler /opt/gocrawler/bin/
RUN chmod +x /opt/gocrawler/bin/gocrawler

CMD /opt/gocrawler/bin/gocrawler
