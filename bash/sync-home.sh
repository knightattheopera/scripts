#!/usr/bin/env bash
# Name: sync-home.sh
# Description: sync home directory to a cloud backup using rclone

set -euo pipefail

# Status with which to exit if we reach the end of the script
exit_status=0

readonly SCRIPT_NAME=$(basename "$0")

readonly USAGE="$SCRIPT_NAME [(-h|--help)] [(--dry-run|--interactive)]"

function log {
    echo "[$SCRIPT_NAME] [$(date +'%Y-%m-%dT%H:%M:%S%z')] [$1] - $2" >&2
}

if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )) ; then
    # empty arrays on bash < 4.4 have behavior we don't want here
    log "error" "bash >= 4.4 required, found $BASH_VERSION"
    exit 1
fi

rclone_options=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|--interactive)
            rclone_options+=("$1")
            shift
            ;;
        -h|--help)
            echo "usage: $USAGE"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            log "error" "unknown option: $1"
            log "error" "usage: $USAGE"
            exit 1
            ;;
        *)
            log "error" "unexpected positional argument: $1"
            log "error" "usage: $USAGE"
            exit 1
            ;;
    esac
done

if ! rclone_bin_path="$(command -v rclone)" ; then
    log "error" "rclone not available"
    exit 1
fi

log "info" "using rclone at '$rclone_bin_path' ($("$rclone_bin_path" version | head -n 1))"

log "info" "using rclone options: ${rclone_options[*]}"


drive_endpoint="gdrive-archivos:Laptop Home"

function sync_no_filter {
    echo
    log "info" "syncing $1..."
    "$rclone_bin_path" sync "${rclone_options[@]}" "$HOME/$1" "$drive_endpoint/$1"
}

sync_no_filter "Documents"
sync_no_filter "books"
sync_no_filter "Music"

echo
log "info" "starting syncs with filters..."

filter_files_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rclone/filters"
general_filter_file="$filter_files_dir/general-filter-file.txt"

if [ ! -f "$general_filter_file" ] ; then
    log "error" "could not find file '$general_filter_file'"
    log "error" "skipping all syncs with filters"
    exit 1
fi

function sync_with_filter {
    echo
    log "info" "syncing $1..."
    log "info" "using filter file: '$general_filter_file'"
    local filter_file_args=("--filter-from=$general_filter_file")
    for filter_file in "${@:2}"; do
        log "info" "using filter file: '$filter_file'"
        if [ ! -f "$filter_file" ]; then
            log "error" "could not find file '$filter_file'"
            log "error" "skipping syncing $1"
            exit_status=1
            return 0
        fi
        filter_file_args+=("--filter-from=$filter_file")
    done
    "$rclone_bin_path" sync "${rclone_options[@]}" --copy-links "${filter_file_args[@]}" "$HOME/$1" "$drive_endpoint/$1"
}

sync_with_filter "coding"
sync_with_filter "courses" "$filter_files_dir/courses-filter-file.txt"

if [ "$exit_status" -ne 0 ] ; then
    log "info" "done, but found some errors"
    exit "$exit_status"
fi

log "info" "done"
