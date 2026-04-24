FROM golang:1.25-alpine AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$(go env GOARCH) go build -mod=vendor -o /out/keygen .

FROM alpine:3.21
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY BUILD_INFO.json /app/BUILD_INFO.json
COPY --from=builder /out/keygen /app/bin/keygen
RUN chmod +x /app/bin/keygen && mkdir -p /app/data
VOLUME ["/app/data"]
EXPOSE 9090
CMD ["/app/bin/keygen", "-web", "-addr", "0.0.0.0:9090", "-db", "/app/data/keygen.db"]
