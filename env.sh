# environment setup for this project's scripts

if [ -z "$SCRIPTS_BASE_DIR" ] ; then
    echo "scripts env.sh: SCRIPTS_BASE_DIR was not set, failed to setup environment." >&2
    return 1
fi

if [ -d "$SCRIPTS_BASE_DIR/bash" ] && command -v bash >/dev/null ; then
    export PATH="$PATH:$SCRIPTS_BASE_DIR/bash"
fi

if [ -d "$SCRIPTS_BASE_DIR/python" ] && command -v python3.11 >/dev/null ; then
    export PATH="$PATH:$SCRIPTS_BASE_DIR/python"
fi

if [ -d "$SCRIPTS_BASE_DIR/uv" ] && command -v uv >/dev/null ; then
    export PATH="$PATH:$SCRIPTS_BASE_DIR/uv"
fi

