FROM golang:1.25-alpine AS builder

WORKDIR /app

ENV CGO_ENABLED=0

# Copy manifests
COPY go.mod go.sum* ./

# Drop the local replace and fetch the latest package directly from GitHub
RUN go mod edit -dropreplace github.com/arthursoares/things-cloud-sdk && \
    go get github.com/arthursoares/things-cloud-sdk@main && \
    go mod download

# Copy application source and build
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