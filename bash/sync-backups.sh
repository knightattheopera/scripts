#!/usr/bin/env bash
# Name: sync-backups.sh
# Description: sync backups directory to the cloud using rclone

set -euo pipefail

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

while [[ $# -gt 0 ]] ; do
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

drive_endpoint="gdrive-archivos:Backups"

"$rclone_bin_path" sync "${rclone_options[@]}" "$HOME/backups" "$drive_endpoint"

log "info" "done"
