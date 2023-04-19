# BASE
FROM --platform=$BUILDPLATFORM us-docker.pkg.dev/omg-img/ordermygear/go:v1.17.13-1 AS base
ARG TARGETARCH
ARG TARGETOS
ARG GH_TOKEN
RUN git config --global url."https://$GH_TOKEN@github.com".insteadOf "https://github.com"
WORKDIR /builder/
COPY go.mod go.sum ./
RUN go mod download
COPY . ./
RUN update-migration migration-template-service migrations


# LINTER
FROM base AS linter
RUN golangci-lint run


# TESTER
FROM linter AS tester
RUN go test ./... -coverprofile=c.out -race


# BUILDER
FROM tester AS builder
RUN mkdir -p /builder/.build/bin
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags="-s -w" -o /builder/.build/bin ./...


# RUNTIME
FROM gcr.io/distroless/base
USER 999
CMD ["/go/bin/template-service"]
EXPOSE 8080
COPY --from=builder --chown=999 /builder/deploy /deploy
COPY --from=builder --chown=999 /builder/migrations /migrations
COPY --from=builder --chown=999 /builder/.build/bin /go/bin
