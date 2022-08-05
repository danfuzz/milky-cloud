# Copyright 2022 Dan Bornstein.
# Licensed AS IS and WITHOUT WARRANTY under the Apache License,
# Version 2.0. Details: <http://www.apache.org/licenses/LICENSE-2.0>

#
# Global variable setup
#

# Symlink-resolved command name (not of this file, but our top-level includer).
_stderr_cmdName="$(readlink -f "$0")" || return "$?"
_stderr_cmdName="${_stderr_cmdName##*/}"

# Has an error been emitted?
_stderr_anyErrors=0

# Whether error messages are enabled.
_stderr_errorEnabled=1

# Whether progress messages are enabled.
_stderr_progressEnabled=0


#
# Library functions
#

# Prints an error message to stderr, if such are enabled.
#
# --no-name -- Suppress printing of the top-level command name on the first
#   message.
# --read -- Read messages from stdin.
# --set=0|1 -- Enable or disable error message printing.
#
# Note: Error messages are _enabled_ by default.
function error-msg {
    local printName="$(( !_stderr_anyErrors ))"
    local readStdin=0
    local wasCmd=0

    while [[ $1 =~ ^-- ]]; do
        case "$1" in
            --no-name)
                printName=0
                ;;
            --read)
                readStdin=1
                ;;
            --set=1|--set=0)
                _stderr_stderrEnabled="${1#*=}"
                wasCmd=1
                ;;
            --)
                shift
                break
                ;;
            *)
                error-msg "Unrecognized option: $1"
                return 1
                ;;
        esac
        shift
    done

    if (( wasCmd || !_stderr_errorEnabled )); then
        return
    fi

    if (( printName )); then
        printf 1>&2 '%s: ' "${_stderr_cmdName}"
    fi

    if (( readStdin )); then
        cat 1>&2
    else
        # `printf` to avoid option-parsing weirdness with `echo`.
        printf 1>&2 '%s\n' "$*"
    fi

    _stderr_anyErrors=1
}

# Prints a "progress" message to stderr, if such are enabled.
#
# --read -- Read messages from stdin.
# --print-option -- Prints `--progress` or `--no-progress` to stdout, reflecting
#   the enabled status. (This is to make it easy to propagate the progress state
#   down into another command.)
# --set=0|1 -- Enable or disable error message printing.
# --status -- Prints `1` or `0` to stdout, to indicate enabled status.
#
# Note: Progress messages are _disabled by default.
function progress-msg {
    local readStdin=0
    local wasCmd=0

    while [[ $1 =~ ^-- ]]; do
        case "$1" in
            --read)
                readStdin=1
                ;;
            --print-option)
                (( _stderr_progressEnabled )) \
                && echo '--progress' \
                || echo '--no-progress'
                wasCmd=1
                ;;
            --set=1|--set=0)
                _stderr_progressEnabled="${1#*=}"
                wasCmd=1
                ;;
            --status)
                echo "${_stderr_progressEnabled}"
                wasCmd=1
                ;;
            --)
                shift
                break
                ;;
            *)
                error-msg "Unrecognized option: $1"
                return 1
                ;;
        esac
        shift
    done

    if (( wasCmd || !_stderr_progressEnabled )); then
        return
    fi

    if (( readStdin )); then
        cat 1>&2
    else
        # `printf` to avoid option-parsing weirdness with `echo`.
        printf 1>&2 '%s\n' "$*"
    fi
}
