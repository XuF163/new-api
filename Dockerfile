FROM oven/bun:latest AS builder

WORKDIR /build
ENV CI=""
ARG NODE_OPTIONS="--max-old-space-size=2048"
ENV NODE_OPTIONS=$NODE_OPTIONS
COPY web/package.json .
COPY web/bun.lock .
COPY ./web .
COPY ./VERSION .
# If web/dist already exists in build context, reuse it to avoid a heavy Vite build on low-memory servers.
# Otherwise, build it.
RUN /bin/sh -c 'set -e; if [ -d dist ] && [ -f dist/index.html ]; then echo "[web] using prebuilt dist/"; else bun install && DISABLE_ESLINT_PLUGIN="true" VITE_REACT_APP_VERSION="$(cat VERSION)" bun run build; fi'

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
