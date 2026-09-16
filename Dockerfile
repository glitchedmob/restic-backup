FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

LABEL org.opencontainers.image.title="restic-backup" \
      org.opencontainers.image.description="Minimal Restic, SQLite, and Supercronic backup tools" \
      org.opencontainers.image.source="https://github.com/glitchedmob/restic-backup"

RUN apk add --no-cache \
        ca-certificates \
        jq \
        restic \
        sqlite \
        supercronic \
    && addgroup -g 65532 backup \
    && adduser -D -H -u 65532 -G backup backup \
    && mkdir -p /cache /scratch /etc/backup \
    && chown backup:backup /cache /scratch

ENV HOME=/tmp \
    RESTIC_CACHE_DIR=/cache \
    TZ=UTC

USER 65532:65532
WORKDIR /scratch

CMD ["supercronic", "/etc/backup/crontab"]
