# Scripts

A collection of useful scripts I've written.

## Usage

You can run the scripts by addressing them by their full path,
but you can also add the following lines to your `~/.bashrc`.

```bash ~/.bashrc
SCRIPTS_BASE_DIR="/path/to/this/repo"
if [ -f "$SCRIPTS_BASE_DIR/env.sh" ] ; then
    source "$SCRIPTS_BASE_DIR/env.sh"
fi
unset SCRIPTS_BASE_DIR
```

