#!/bin/sh
set -eu
umask 077

test "$(id -u)" -ne 0
restic version
sqlite3 --version
supercronic -version
jq --version
test -s /etc/ssl/certs/ca-certificates.crt
for unwanted in docker rclone resticprofile gcc node npm; do
    if command -v "$unwanted" >/dev/null 2>&1; then
        echo "Unexpected tool in runtime image: $unwanted" >&2
        exit 1
    fi
done

work=$(mktemp -d)
writer_pid=
scheduler_pid=
cleanup() {
    if [ -n "$scheduler_pid" ]; then
        kill "$scheduler_pid" 2>/dev/null || true
        wait "$scheduler_pid" 2>/dev/null || true
    fi
    if [ -n "$writer_pid" ]; then
        kill "$writer_pid" 2>/dev/null || true
        wait "$writer_pid" 2>/dev/null || true
    fi
    rm -rf "$work"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
mkdir "$work/source" "$work/snapshot"

# Keep a writer connection open so committed rows remain in the live WAL.
mkfifo "$work/sqlite-input"
sqlite3 "$work/source/app.db" < "$work/sqlite-input" > "$work/sqlite.log" &
writer_pid=$!
exec 3> "$work/sqlite-input"
printf '%s\n' \
    'PRAGMA journal_mode=WAL;' \
    'PRAGMA wal_autocheckpoint=0;' \
    'CREATE TABLE records (value TEXT);' \
    "INSERT INTO records VALUES ('committed WAL data');" >&3

ready=false
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if [ -s "$work/source/app.db-wal" ] && \
        [ "$(sqlite3 -readonly "$work/source/app.db" 'SELECT count(*) FROM records;' 2>/dev/null || true)" = 1 ]; then
        ready=true
        break
    fi
    sleep 1
done
[ "$ready" = true ]
sqlite3 -readonly "$work/source/app.db" '.timeout 5000' ".backup '$work/snapshot/app.db'"
[ "$(sqlite3 -readonly "$work/snapshot/app.db" 'PRAGMA integrity_check;')" = ok ]
[ "$(sqlite3 -readonly "$work/snapshot/app.db" 'SELECT value FROM records;')" = 'committed WAL data' ]

# A missing database must fail rather than silently produce an empty backup.
if sqlite3 -readonly "$work/source/missing.db" ".backup '$work/snapshot/missing.db'" 2>/dev/null; then
    echo 'Opening a missing database unexpectedly succeeded' >&2
    exit 1
fi
[ ! -e "$work/source/missing.db" ]

export RESTIC_REPOSITORY="$work/repository"
export RESTIC_PASSWORD='integration-test-only'
export RESTIC_CACHE_DIR="$work/cache"
printf '%s\n' 'fixture private key' > "$work/snapshot/private.key"
restic --quiet init
restic --quiet backup --host backup-test "$work/snapshot"
restic --quiet check --read-data
restic --quiet restore latest --target "$work/restored"
restored_db=$(find "$work/restored" -name app.db)
restored_key=$(find "$work/restored" -name private.key)
[ "$(sqlite3 -readonly "$restored_db" 'PRAGMA integrity_check;')" = ok ]
[ "$(sqlite3 -readonly "$restored_db" 'SELECT value FROM records;')" = 'committed WAL data' ]
cmp "$work/snapshot/private.key" "$restored_key"
[ "$(restic snapshots --json | jq length)" = 1 ]

# Exercise scheduling under the same unprivileged, read-only-root setup.
printf '* * * * * * * printf scheduled > %s/tick\n' "$work" > "$work/crontab"
supercronic -test "$work/crontab"
supercronic "$work/crontab" > "$work/scheduler.log" 2>&1 &
scheduler_pid=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if [ -s "$work/tick" ]; then
        break
    fi
    sleep 1
done
[ "$(head -c 9 "$work/tick")" = scheduled ]

printf '%s\n' 'PASS: non-root runtime, live-WAL SQLite snapshot, encrypted backup/restore, and scheduled execution'
