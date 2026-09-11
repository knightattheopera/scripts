# environment setup for this project's scripts
# must be sourced from bash (e.g. from `~/.bashrc`), not executed
if [ -z "${BASH_VERSION:-}" ] ; then
    echo "scripts env.sh error: env.sh requires bash" >&2
    return 1 2>/dev/null || exit 1
fi

if [ "${BASH_SOURCE[0]}" = "$0" ] ; then
    echo "scripts env.sh error: env.sh must be sourced, not executed" >&2
    exit 1
fi

# get this file's parent directory
#
# this might break if this file is `source`'d as a symlink
if ! __scripts_base_dir="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" ; then
    echo "scripts env.sh error: failed to locate scripts dir" >&2
    return 1
fi

function __add_to_path {
    case ":$PATH:" in
        *":$1:"*)
            ;;
        *)
            # we append, our scripts are non-essential
            # and should not shadow other tooling
            PATH="${PATH:+$PATH:}$1"
            ;;
    esac
}

if [ -d "$__scripts_base_dir/bash" ] ; then
    __add_to_path "$__scripts_base_dir/bash"
fi

if [ -d "$__scripts_base_dir/python" ] && command -v python3.14 >/dev/null ; then
    # scripts in this dir must declare
    # a shebang with python3.14
    #
    # for other versions of python,
    # `uv` should be used instead
    __add_to_path "$__scripts_base_dir/python"
fi

if [ -d "$__scripts_base_dir/uv" ] && command -v uv >/dev/null ; then
    __add_to_path "$__scripts_base_dir/uv"
fi

export PATH
unset -f __add_to_path
unset __scripts_base_dir
