FROM ghcr.io/creativeprojects/resticprofile:0.35.0@sha256:e5e45b4994d09dd26e8fdb5be3d1c663dcaf282e2d8c758c422e67aaeafc855c

LABEL org.opencontainers.image.title="restic-backup" \
      org.opencontainers.image.description="Official Resticprofile image with SQLite backup tools" \
      org.opencontainers.image.source="https://github.com/glitchedmob/restic-backup"

RUN apk add --no-cache sqlite supercronic
