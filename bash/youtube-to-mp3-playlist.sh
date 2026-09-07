#!/usr/bin/env bash
# Name: youtube-to-mp3-playlist.sh
# Description: download a youtube playlist or a video as mp3 files
# Note: There must be an active youtube session in your browser of choice

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly USAGE="$SCRIPT_NAME \
    [(-h|--help)] \
    (-vu|--video-url|-pu|--playlist-url) <url> \
    (-o|--output-dir) <dir> \
    [-b|--browser (firefox|chromium)] \
    [(-v|--verbose)]"

function log {
    echo "[$SCRIPT_NAME] [$(date +'%Y-%m-%dT%H:%M:%S%z')] [$1] - $2" >&2
}

#######################################
# Get the cookies path expected by `yt-dlp`.
# Arguments:
#   The browser name, as defined by `yt-dlp`, e.g. "firefox" or "chromium".
#   The data directory where the browser saves data, a path.
#   The name of the cookies file to look for inside the data directory.
# Outputs:
#   The browser data path <browser-name>:<browser-data-dir> if a cookies file was found,
#   safely falling back to just <browser-name> if the search failed.
#######################################
function get_cookies_path {
    local browser_name="$1"
    local browser_data_dir="$2"
    local cookies_file_name="$3"

    log "info" "getting cookies from browser $browser_name"
    log "info" "note that this requires having an active youtube session on $browser_name"
    if [ -d "$browser_data_dir" ] ; then
        # attempt to find the cookies file explicitly
        log "info" "attempting to find a file named '$cookies_file_name' in directory '$browser_data_dir'"
        # note: the direct `local` assignment intentionally masks the return code of the `find` command:
        # if `find` fails we don't want the script to crash under `set -e`, we just want to fallback
        # to the safe `$browser_name` path
        local cookies_file_path="$(find "$browser_data_dir" -name "$cookies_file_name" -print -quit 2>/dev/null)"
        if [ -n "$cookies_file_path" ] ; then
            log "info" "found cookies file for browser $browser_name at '$cookies_file_path'"
            log "info" "using cookies directory: '$browser_data_dir'"
            # `yt-dlp` should be able to find the cookies file if we did
            echo "$browser_name:$browser_data_dir"
            return 0
        fi
    fi
    # if we can't find the cookies file
    # we can still default to the browser name
    log "info" "failed to find cookies file for browser $browser_name, falling back to default path"
    echo "$browser_name"
}

function require_argument {
    if [[ $# -lt 2 ]] ; then
        log "error" "'$1' requires an argument"
        log "error" "usage: $USAGE"
        exit 1
    fi

    if [[ "$2" == -* ]] ; then
        log "error" "invalid argument for option '$1': '$2'"
        log "error" "usage: $USAGE"
        exit 1
    fi

    # none of the options accept empty arguments
    if [ -n "$2" ] ; then
        log "error" "empty argument for option '$1'"
        log "error" "usage: $USAGE"
        exit 1
    fi
}

if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )) ; then
    # empty arrays on bash < 4.4 have behavior we don't want here
    log "error" "bash >= 4.4 required, found $BASH_VERSION"
    exit 1
fi

url=""
is_video=false
output_dir=""
browser_name=""
yt_dlp_options=()

# argument parsing
while [[ $# -gt 0 ]] ; do
    case "$1" in
        -vu|--video-url)
            require_argument "$@"
            if [ -n "$url" ] ; then
                log "error" "you can only provide one url"
                log "error" "usage: $USAGE"
                exit 1
            fi
            url="$2"
            is_video=true
            shift 2
            ;;
        -pu|--playlist-url)
            require_argument "$@"
            if [ -n "$url" ] ; then
                log "error" "you can only provide one url"
                log "error" "usage: $USAGE"
                exit 1
            fi
            url="$2"
            is_video=false
            shift 2
            ;;
        -o|--output-dir)
            require_argument "$@"
            if [ -n "$output_dir" ] ; then
                log "error" "you can only provide one output directory"
                log "error" "usage: $USAGE"
                exit 1
            fi
            output_dir="$2"
            shift 2
            ;;
        -b|--browser)
            require_argument "$@"
            if [ -n "$browser_name" ] ; then
                log "error" "you can only provide one browser name"
                log "error" "usage: $USAGE"
                exit 1
            fi
            case "$2" in
                firefox|chromium)
                    browser_name="$2"
                    ;;
                *)
                    log "error" "unknown browser: $2"
                    log "error" "usage: $USAGE"
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        -v|--verbose)
            yt_dlp_options+=("$1")
            shift
            ;;
        -h|--help)
            echo "usage: $USAGE"
            exit 0
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

if [ -z "$url" ] ; then
    log "error" "no url was provided"
    log "error" "usage: $USAGE"
    exit 1
fi

if [ -z "$output_dir" ] ; then
    log "error" "output dir not provided"
    log "error" "usage: $USAGE"
    exit 1
fi

if [ -z "$browser_name" ] ; then
    browser_name="chromium"
fi

if [ "$is_video" = true ] ; then
    log "info" "will download video from: '$url'"
else
    log "info" "will download playlist from: '$url'"
fi

log "info" "using output dir: '$output_dir'"

# Ensure the main dependencies are installed
if ! command -v ffmpeg >/dev/null ; then
    log "error" "\`ffmpeg\` not available"
    log "error" "\`ffmpeg\` is required for mp3 extraction"
    exit 1
fi

if ! uvx_bin_path="$(command -v uvx)" ; then
    log "error" "\`uvx\` not available"
    exit 1
fi
log "info" "using \`uvx\` at '$uvx_bin_path' ($("$uvx_bin_path" --version))"

yt_dlp_command=("$uvx_bin_path" "--with" "yt-dlp-getpot-wpc" "--with" "secretstorage" "--with" "yt-dlp-ejs" "yt-dlp")
log "info" "using \`yt-dlp\` command: '${yt_dlp_command[*]}'"
if ! yt_dlp_version=$("${yt_dlp_command[@]}" --version) ; then
    log "error" "failed to get \`yt-dlp\` version"
    exit 1
fi
log "info" "using \`yt-dlp\` version $yt_dlp_version"

# note: we check for the data directories of flatpak installs only
#
# keep in mind that `yt-dlp` will still try to find the cookies
# by itself, so this should not be an issue in most cases
case "$browser_name" in
    chromium)
        cookies_path=$(get_cookies_path "chromium" "$HOME/.var/app/org.chromium.Chromium/" "Cookies")
        ;;
    firefox)
        cookies_path=$(get_cookies_path "firefox" "$HOME/.var/app/org.mozilla.firefox/" "cookies.sqlite")
        ;;
    *)
        # this is unreachable, but let's be defensive
        log "error" "unknown browser: $browser_name"
        exit 1
        ;;
esac
cookies_options=("--cookies-from-browser" "$cookies_path")

js_runtimes_options=()
if ! command -v node >/dev/null ; then
    log "error" "\`node\` not available"
    log "error" "\`node\` is required for solving javascript challenges"
    exit 1
fi
js_runtimes_options+=("--js-runtimes" "node")


format_options=("--format" "ba" "--extract-audio" "--audio-format" "mp3" "--audio-quality" "0")
log "info" "using format options: ${format_options[*]}"

extractor_args_options=("--extractor-args" "youtube:player_client=default,web_embedded,web_music")

yt_dlp_options+=( "${cookies_options[@]}" )
yt_dlp_options+=( "${format_options[@]}" )
yt_dlp_options+=( "${js_runtimes_options[@]}" )
yt_dlp_options+=( "${extractor_args_options[@]}" )
yt_dlp_options+=( "--paths" "$output_dir" )

mkdir -p -- "$output_dir"

if [ "$is_video" = true ] ; then
    log "info" "downloading video as mp3 playlist: '$url'"
    "${yt_dlp_command[@]}" \
        "${yt_dlp_options[@]}" \
        --split-chapters \
        --output "%(title)s_full.%(ext)s" \
        --output "chapter:%(section_number)02d %(section_title)s.%(ext)s" "$url"
else
    log "info" "downloading playlist as mp3 playlist: '$url'"
    "${yt_dlp_command[@]}" \
        "${yt_dlp_options[@]}" \
        --output "%(playlist_index)02d %(title)s.%(ext)s" "$url"
fi

log "info" "done"
