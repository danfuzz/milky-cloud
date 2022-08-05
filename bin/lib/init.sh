#!/bin/bash
#
# Copyright 2022 Dan Bornstein.
# Licensed AS IS and WITHOUT WARRANTY under the Apache License,
# Version 2.0. Details: <http://www.apache.org/licenses/LICENSE-2.0>

if [[ ${_milky_cloud_libDir} != '' ]]; then
    echo 1>&2 'Warning: Not reinitializing library!'
    return 1
fi

# The symlink-resolved path of the command that is running (that is, the
# top-level script).
_milky_cloud_cmdPath="$(readlink -f "$0")" || return "$?"

# Figure out the symlink-resolved directory of this script.
_milky_cloud_libDir="$(readlink -f "${BASH_SOURCE[0]}")" || return "$?"
_milky_cloud_libDir="${_milky_cloud_libDir%/*}"

# Figure out the "main" directory. If `cmdDir` is the same as `libDir`, then
# we're running a library script, and the main directory is the parent of
# `libDir`. Otherwise, the main directory is `cmdDir`.
if [[ ${_milky_cloud_cmdDir} == ${_milky_cloud_libDir} ]]; then
    _milky_cloud_mainDir="$(cd "${_milky_cloud_libDir}/.."; /bin/pwd)"
else
    _milky_cloud_mainDir="${_milky_cloud_cmdDir}"
fi


#
# Library functions: Convenience callers for external scripts. These are for
# items that are used often enough to be shorter to name, or in contexts that
# require a simple function name.
#

# Calls `lib aws-json ec2`.
function ec2-json {
    lib aws-json ec2 "$@"
}

# Calls `lib json-array`.
function jarray {
    lib json-array "$@"
}

# Calls `lib json-get`.
function jget {
    lib json-get "$@"
}

# Calls `lib json-val`.
function jval {
    lib json-val "$@"
}

# Calls `lib parse-location --input-zone`.
function parse-zone {
    lib parse-location --input=zone "$@"
}

# Calls `lib parse-location --print-region`.
function region-from-location {
    lib parse-location --output=region "$@"
}


#
# Library functions: Others
#

# Load the argument processor library.
. "${_milky_cloud_libDir}/arg-processor.sh"

# Gets the directory of this command, "this command" being the main script that
# is running.
function this-cmd-dir {
    echo "${_milky_cloud_cmdPath%/*}"
}

# Gets the name of this command, that is, "this command" being the main script
# that is running.
function this-cmd-name {
    echo "${_milky_cloud_cmdPath##*/}"
}

# Gets the full path of this command, "this command" being the main script that
# is running.
function this-cmd-path {
    echo "${_milky_cloud_cmdPath}"
}

# Calls through to an arbitrary library script.
function lib {
    if (( $# == 0 )); then
        echo 1>&2 'Missing library script name.'
        return 1
    fi

    local name="$1"
    shift

    if ! [[ ${name} =~ ^[-a-z]+$ ]]; then
        echo 1>&2 'Weird script name:' "${name}"
        return 1
    elif [[ -x "${_milky_cloud_libDir}/${name}" ]]; then
        # It's in the internal helper library.
        "${_milky_cloud_libDir}/${name}" "$@"
    elif [[ -x "${_milky_cloud_mainDir}/${name}" ]]; then
        # It's an exposed script.
        "${_milky_cloud_mainDir}/${name}" "$@"
    else
        echo 1>&2 'No such library script:' "${name}"
        return 1
    fi
}

# Whether progress messages are enabled.
_milky_cloud_progressEnabled=0

# Prints a "progress" message to stderr, if such are enabled. Use
# `progress-msg-switch` to change or check the enabled status of progress
# messages.
function progress-msg {
    if (( _milky_cloud_progressEnabled )); then
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
            _milky_cloud_progressEnabled=1
            ;;
        --disable|0)
            _milky_cloud_progressEnabled=0
            ;;
        --print-option)
            (( _milky_cloud_progressEnabled )) \
            && echo '--progress' \
            || echo '--no-progress'
            ;;
        --status)
            echo "${_milky_cloud_progressEnabled}"
            ;;
        *)
            echo 1>&2 "Unrecognized argument: $1"
            return 1
    esac
}


#
# Library initialization
#

# Calls the prerequisite checker if it doesn't seem to have yet been run in this
# session.
if [[ ${MILKY_CLOUD_PREREQUISITES_DONE} != 1 ]]; then
    if lib check-prerequisites; then
        export MILKY_CLOUD_PREREQUISITES_DONE=1
    else
        echo 1>&2 'Failed one or more prerequisite checks!'
        exit 1
    fi
fi
