# restic-backup

The official Alpine-based Resticprofile image from GHCR, with SQLite and Supercronic for non-root scheduling.

```sh
docker pull ghcr.io/glitchedmob/restic-backup:1.0.0
```

## Usage

Mount your Resticprofile configuration under `/resticprofile` and pass profile commands directly:

```sh
docker run --rm -v "$PWD:/resticprofile:ro" ghcr.io/glitchedmob/restic-backup:1.0.0 profiles
```

The image inherits the upstream `resticprofile` entrypoint and defaults to root. Set the user and writable cache, lock, and scratch paths in your Compose configuration. No Docker socket is needed.

## Build

```sh
docker build -t restic-backup:local .
```

## Releases

Pushes to `main` create versioned GitHub releases and publish AMD64/ARM64 images to GHCR with version and `latest` tags.
