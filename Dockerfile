FROM oven/bun:latest AS builder

WORKDIR /build
ENV CI=""
ENV NODE_OPTIONS="--max-old-space-size=4096"
COPY web/package.json .
COPY web/bun.lock .
RUN bun install
COPY ./web .
COPY ./VERSION .
# HF Spaces can abort long-running steps with little/no output; keep a small heartbeat during the build.
RUN /bin/sh -c 'set -e; ( while :; do echo "[web] vite build still running..."; sleep 30; done ) & ticker=$!; trap "kill $ticker" EXIT; DISABLE_ESLINT_PLUGIN="true" VITE_REACT_APP_VERSION="$(cat VERSION)" bun run build'

FROM golang:alpine AS builder2
ENV GO111MODULE=on CGO_ENABLED=0

ARG TARGETOS
ARG TARGETARCH
ENV GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64}
ENV GOEXPERIMENT=greenteagc

WORKDIR /build

ADD go.mod go.sum ./
RUN go mod download

COPY . .
COPY --from=builder /build/dist ./web/dist
RUN go build -ldflags "-s -w -X 'github.com/QuantumNous/new-api/common.Version=$(cat VERSION)'" -o new-api

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tzdata libasan8 wget \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

COPY --from=builder2 /build/new-api /
# Default listen port for normal server deployments.
ENV PORT=3000

EXPOSE 3000
WORKDIR /data
ENTRYPOINT ["/new-api"]
