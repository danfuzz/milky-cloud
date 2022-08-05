# Copyright 2022 Dan Bornstein.
# Licensed AS IS and WITHOUT WARRANTY under the Apache License,
# Version 2.0. Details: <http://www.apache.org/licenses/LICENSE-2.0>

if [[ ${_milky_cloud_libDir} != '' ]]; then
    echo 1>&2 'Warning: Not reinitializing library!'
    return 1
fi

#
# Global variable setup
#

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
    _milky_cloud_mainDir="${_milky_cloud_cmdPath%/*}"
fi


#
# Prerequisites checker
#
# This is arranged to only do prerequisite checks once per high-level script
# call, instead of re-re-...-doing it multiple times.
#

if [[ ${MILKY_CLOUD_PREREQUISITES_DONE} != 1 ]]; then
    . "${_milky_cloud_libDir}/init-check-prereqs.sh" \
    || {
        echo 1>&2 'Failed one or more prerequisite checks!'
        return 1
    }

    export MILKY_CLOUD_PREREQUISITES_DONE=1
fi


#
# Sibling libararies
#

. "${_milky_cloud_libDir}/arg-processor.sh"    # Argument processor.
. "${_milky_cloud_libDir}/stderr-messages.sh"  # Error and progress messages.
. "${_milky_cloud_libDir}/init-wrappers.sh"    # Simple command wrappers.


#
# More library functions
#

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
