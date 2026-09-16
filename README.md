# restic-backup

A small Alpine image with Restic, SQLite, Supercronic, jq, and CA certificates.
Built for per-application backup sidecars. No application code, Node.js, rclone,
Docker CLI, or build toolchain is included.

```sh
docker pull ghcr.io/glitchedmob/restic-backup:1.0.0
```

Published for `linux/amd64` and `linux/arm64`. Prefer a version tag or digest over
`latest` in deployments.

## Runtime

The default command is `supercronic /etc/backup/crontab`. Mount an app-specific
crontab and backup scripts read-only. The image intentionally contains no backup
policy, credentials, repository initialization, or automatic restore behavior.

- Runs as UID/GID `65532:65532` by default. Override `user` to match the app's data owner.
- Supports a read-only root filesystem, dropped capabilities, and `no-new-privileges`.
- Schedules use UTC. No timezone database is included.
- `/cache` is the default Restic cache. `/scratch` is the working directory for temporary snapshots.
- Supply writable cache and scratch mounts owned by the selected UID/GID. Use disk-backed scratch storage for large databases.
- No Docker socket is needed.

Example service, with the scripts and schedule maintained beside the application:

```yaml
services:
  headscale-backup:
    image: ghcr.io/glitchedmob/restic-backup:1.0.0
    hostname: headscale-backup
    user: "10001:10001"
    restart: unless-stopped
    read_only: true
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    environment:
      RESTIC_REPOSITORY: b2:your-bucket:compose/headscale
      RESTIC_PASSWORD_FILE: /run/secrets/restic_password
    env_file: ./secrets/b2.env
    volumes:
      - ./crontab:/etc/backup/crontab:ro
      - ./backup.sh:/etc/backup/backup.sh:ro
      - ./data:/source:ro
      - ./backup-cache:/cache
      - ./backup-scratch:/scratch
    tmpfs:
      - /tmp:rw,nosuid,nodev,noexec,size=16m,mode=1777
    secrets:
      - restic_password

secrets:
  restic_password:
    file: ./secrets/restic-password
```

An example crontab entry is `0 8 * * * /bin/sh /etc/backup/backup.sh`.
Supercronic reads the container environment and does not use a username column.
Backup scripts should set `umask 077`, use SQLite's online backup API rather than
copying a live database, stop on preparation errors, and clean scratch files on
success, failure, and the next startup after an interrupted run. A failed backup
must not be reported as successful to external monitoring.

Override the command for one-off operations, for example:

```sh
docker compose run --rm headscale-backup restic snapshots
```

## Build locally

```sh
docker build -t restic-backup:local .
```

## Releases

The workflows follow the semantic-release and native multi-architecture build
pattern used by `sgfdevs/sgf.dev`, `sgfdevs/methodconf.com`, and
`sgfdevs/cms.methodconf.com`.

Every push to `main`, including a merged PR, creates a release. Conventional
Commits select the version: breaking changes produce a major release, `feat`
produces a minor release, and other changes produce a patch release. The first
release is `1.0.0`. Release tooling runs only in GitHub Actions, never in the image.

The publishing workflow builds on native AMD64 and ARM64 runners,
pushes architecture-specific tags, then publishes the version and `latest`
multi-architecture manifests. It adds the image reference to the GitHub release.
If publishing fails after release creation, rerun the failed jobs for that run.

Dependabot opens updates for the Alpine base image and GitHub Actions. Alpine
runtime packages come from the selected stable release's signed repositories.

### Public GHCR access

A public repository does not automatically make a new GHCR package public. After
the first publication, open the package settings and change its visibility to
**Public**. GitHub does not provide a supported CLI/API operation for this setting.

https://github.com/users/glitchedmob/packages/container/restic-backup/settings

Verify the published image can be pulled without registry credentials before
using it in deployments.
