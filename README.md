# restic-backup

Lightweight Alpine image with Restic, SQLite, Supercronic, jq, and CA certificates.

```sh
docker pull ghcr.io/glitchedmob/restic-backup:1.0.0
```

## Usage

Mount your app's backup script and crontab under `/etc/backup`. The default command runs `supercronic /etc/backup/crontab` with schedules in UTC.

The image runs as `65532:65532`. Override the user to match your app's data owner. Mount writable `/cache` and `/scratch` directories with matching ownership, and provide Restic credentials through your Compose configuration. No Docker socket is needed.

## Build

```sh
docker build -t restic-backup:local .
```

## Releases

Pushes to `main` create versioned GitHub releases and publish AMD64/ARM64 images to GHCR with version and `latest` tags.
