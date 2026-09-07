#!/usr/bin/env bash
# Name: sync-backups.sh
# Description: sync backups directory to the cloud using rclone

set -euo pipefail

SCRIPT_NAME=$(basename "$0")

function log {
    echo "[$SCRIPT_NAME] [$1] - $2" >&2
}

if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )) ; then
    # empty arrays on bash < 4.4 have behavior we don't want here
    log "error" "bash >= 4.4 required, found $BASH_VERSION"
    exit 1
fi

RCLONE_OPTIONS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|--interactive)
            RCLONE_OPTIONS+=("$1")
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            log "error" "unknown option: $1"
            exit 1
            ;;
        *)
            log "error" "unexpected positional argument: $1"
            exit 1
            ;;
    esac
done

if ! RCLONE_BIN_PATH="$(command -v rclone)" ; then
    log "error" "rclone not available"
    exit 1
fi

log "info" "using rclone at '$RCLONE_BIN_PATH' ($($RCLONE_BIN_PATH version | head -n 1))"

log "info" "using rclone options: ${RCLONE_OPTIONS[*]}"

DRIVE_ENDPOINT="gdrive-archivos:Backups"

"$RCLONE_BIN_PATH" sync "${RCLONE_OPTIONS[@]}" "$HOME/backups" "$DRIVE_ENDPOINT"

log "info" "done"
