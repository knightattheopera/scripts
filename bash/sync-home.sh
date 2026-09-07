#!/usr/bin/env bash
# Name: sync-home.sh
# Description: sync home directory to a cloud backup using rclone

set -euo pipefail

# Status with which to exit if we reach the end of the script
EXIT_STATUS=0

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


DRIVE_ENDPOINT="gdrive-archivos:Laptop Home"

function sync_no_filter {
    echo
    log "info" "syncing $1..."
    "$RCLONE_BIN_PATH" sync "${RCLONE_OPTIONS[@]}" "$HOME/$1" "$DRIVE_ENDPOINT/$1"
}

sync_no_filter "Documents"
sync_no_filter "books"
sync_no_filter "Music"

echo
log "info" "starting syncs with filters..."

FILTER_FILES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rclone/filters"
GENERAL_FILTER_FILE="$FILTER_FILES_DIR/general-filter-file.txt"

if [ ! -f "$GENERAL_FILTER_FILE" ] ; then
    log "error" "could not find file '$GENERAL_FILTER_FILE'"
    log "error" "skipping all syncs with filters"
    exit 1
fi

function sync_with_filter {
    echo
    log "info" "syncing $1..."
    log "info" "using filter file: '$GENERAL_FILTER_FILE'"
    local filter_file_args=("--filter-from=$GENERAL_FILTER_FILE")
    for filter_file in "${@:2}"; do
        log "info" "using filter file: '$filter_file'"
        if [ ! -f "$filter_file" ]; then
            log "error" "could not find file '$filter_file'"
            log "error" "skipping syncing $1"
            EXIT_STATUS=1
            return 0
        fi
        filter_file_args+=("--filter-from=$filter_file")
    done
    "$RCLONE_BIN_PATH" sync "${RCLONE_OPTIONS[@]}" --copy-links "${filter_file_args[@]}" "$HOME/$1" "$DRIVE_ENDPOINT/$1"
}

sync_with_filter "coding"
sync_with_filter "courses" "$FILTER_FILES_DIR/courses-filter-file.txt"

if [ "$EXIT_STATUS" -ne 0 ] ; then
    log "info" "done, but found some errors"
    exit "$EXIT_STATUS"
fi

log "info" "done"
