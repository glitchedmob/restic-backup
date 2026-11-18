FROM ghcr.io/creativeprojects/resticprofile:0.34.0@sha256:f5495831c9ebed368c4241a58752475a90cbbabd1db6c81931933881e6d231d6

LABEL org.opencontainers.image.title="restic-backup" \
      org.opencontainers.image.description="Official Resticprofile image with SQLite backup tools" \
      org.opencontainers.image.source="https://github.com/glitchedmob/restic-backup"

RUN apk add --no-cache sqlite supercronic
