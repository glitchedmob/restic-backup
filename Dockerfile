FROM ghcr.io/creativeprojects/resticprofile:0.33.1@sha256:c8afc532eb7693908ca8f0f0a791f632098268ec8ab1b4b63af1a642894a6ad7

LABEL org.opencontainers.image.title="restic-backup" \
      org.opencontainers.image.description="Official Resticprofile image with SQLite backup tools" \
      org.opencontainers.image.source="https://github.com/glitchedmob/restic-backup"

RUN apk add --no-cache sqlite supercronic
