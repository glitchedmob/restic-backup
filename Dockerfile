FROM ghcr.io/creativeprojects/resticprofile:0.33.1@sha256:348075d8971af4884287b3fd719782015ad764423e0bddc4b93ae3a20eb8ca9f

LABEL org.opencontainers.image.title="restic-backup" \
      org.opencontainers.image.description="Official Resticprofile image with SQLite backup tools" \
      org.opencontainers.image.source="https://github.com/glitchedmob/restic-backup"

RUN apk add --no-cache sqlite
