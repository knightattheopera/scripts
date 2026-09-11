# Scripts

A collection of personal scripts.

## Usage

The scripts can be executed addressing them by their path,
but it might also be useful to add the following lines to `~/.bashrc`.

```bash ~/.bashrc
SCRIPTS_BASE_DIR="/path/to/this/repo"
if [ -f "$SCRIPTS_BASE_DIR/env.sh" ] ; then
    source "$SCRIPTS_BASE_DIR/env.sh"
fi
unset SCRIPTS_BASE_DIR
```

