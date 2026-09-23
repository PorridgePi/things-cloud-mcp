FROM golang:1.25-alpine AS builder

WORKDIR /app

# Install git and certs to allow fetching from GitHub over HTTPS
RUN apk add --no-cache git ca-certificates

ENV CGO_ENABLED=0

# Copy the entire project source first
COPY . .

# Clean out old local replace/require directives, pull remote SDK, and tidy
RUN go mod edit \
        -dropreplace=github.com/arthursoares/things-cloud-sdk \
        -droprequire=github.com/arthursoares/things-cloud-sdk && \
    go get github.com/arthursoares/things-cloud-sdk@latest && \
    go mod tidy

# Build the binary
RUN go build -trimpath -ldflags="-s -w" -o things-mcp .

FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/things-mcp /usr/local/bin/things-mcp

EXPOSE 8080

ENV PORT=8080
ENV DATA_DIR=/data

VOLUME ["/data"]

CMD ["things-mcp"]