FROM alpine:3.21
ARG TARGETARCH
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY BUILD_INFO.json /app/BUILD_INFO.json
COPY bin/keygen-linux-${TARGETARCH} /app/bin/keygen
RUN chmod +x /app/bin/keygen && mkdir -p /app/data
VOLUME ["/app/data"]
EXPOSE 9090
CMD ["/app/bin/keygen", "-web", "-addr", "0.0.0.0:9090", "-db", "/app/data/keygen.db"]
