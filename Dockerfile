FROM golang:1.25-alpine AS builder

WORKDIR /app

# Install git and certs to allow fetching from GitHub over HTTPS
RUN apk add --no-cache git ca-certificates

ENV CGO_ENABLED=0

# Copy manifests
COPY go.mod go.sum* ./

# Drop both the local replace and the invalid dummy requirement, then pull the real remote module
RUN go mod edit \
        -dropreplace=github.com/arthursoares/things-cloud-sdk \
        -droprequire=github.com/arthursoares/things-cloud-sdk && \
    go get github.com/arthursoares/things-cloud-sdk@latest && \
    go mod download

# Copy source and build binary
COPY . .
RUN go build -trimpath -ldflags="-s -w" -o things-mcp .

FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/things-mcp /usr/local/bin/things-mcp

EXPOSE 8080

ENV PORT=8080
ENV DATA_DIR=/data

VOLUME ["/data"]

CMD ["things-mcp"]