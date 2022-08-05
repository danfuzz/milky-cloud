# Copyright 2022 Dan Bornstein.
# Licensed AS IS and WITHOUT WARRANTY under the Apache License,
# Version 2.0. Details: <http://www.apache.org/licenses/LICENSE-2.0>

#
# Global variable setup
#

# Symlink-resolved command name (not of this file, but our top-level includer).
_stderr_cmdName="$(readlink -f "$0")" || return "$?"
_stderr_cmdName="${_stderr_cmdName##*/}"

# Whether error messages are enabled.
_stderr_errorEnabled=0

# Whether progress messages are enabled.
_stderr_progressEnabled=0


#
# Library functions
#

# Prints an error message to stderr, if such are enabled.
#
# Note: Error messages are _enabled_ by default.
function error-msg {
    if (( _stderr_errorEnabled )); then
        echo 1>&2 "$@"
    fi
}

# Enables or disables error messages.
#
# --disable | 0 -- Disables progress messages.
# --enable | 1` -- Enables progress messages.
function error-msg-switch {
    case "$1" in
        --enable|1)
            _stderr_errorEnabled=1
            ;;
        --disable|0)
            _stderr_errorEnabled=0
            ;;
        *)
            echo 1>&2 "Unrecognized argument: $1"
            return 1
    esac
}

# Prints a "progress" message to stderr, if such are enabled. Use
# `progress-msg-switch` to change or check the enabled status of progress
# messages.
function progress-msg {
    if (( _stderr_progressEnabled )); then
        echo 1>&2 "$@"
    fi
}

# Enables, disables, or checks the enabled status of "progress" messages.
#
# --disable | 0 -- Disables progress messages.
# --enable | 1` -- Enables progress messages.
# --print-option -- Prints `--progress` or `--no-progress` to stdout, reflecting
#   the enabled status. (This is to make it easy to propagate the progress state
#   down into another command.)
# --status -- Prints `1` or `0` to stdout, to indicate enabled status.
function progress-msg-switch {
    case "$1" in
        --enable|1)
            _stderr_progressEnabled=1
            ;;
        --disable|0)
            _stderr_progressEnabled=0
            ;;
        --print-option)
            (( _stderr_progressEnabled )) \
            && echo '--progress' \
            || echo '--no-progress'
            ;;
        --status)
            echo "${_stderr_progressEnabled}"
            ;;
        *)
            echo 1>&2 "Unrecognized argument: $1"
            return 1
    esac
}
