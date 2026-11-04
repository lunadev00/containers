# syntax=docker/dockerfile:1
FROM golang:1.27.3-bookworm AS gosu-builder

RUN CGO_ENABLED=0 go install -trimpath -ldflags="-s -w" github.com/tianon/gosu@1.19

FROM mariadb:11.8.9-ubi9

COPY --chmod=0755 --from=gosu-builder /go/bin/gosu /usr/local/bin/gosu

LABEL org.opencontainers.image.title="MariaDB" \
      org.opencontainers.image.description="MariaDB 11.4.11 em UBI 9 para uso local, desenvolvimento e homelab com persistência em volume." \
      org.opencontainers.image.source="https://github.com/lzocateli/containers" \
      org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/mariadb" \
      org.opencontainers.image.url="https://hub.docker.com/r/lzocateli/mariadb" \
      org.opencontainers.image.version="11.4.11-ubi9"

VOLUME ["/var/lib/mysql"]
EXPOSE 3306

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
  CMD mariadb-admin ping -h 127.0.0.1 --silent || exit 1
