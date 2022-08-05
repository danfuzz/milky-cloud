# Copyright 2022 Dan Bornstein.
# Licensed AS IS and WITHOUT WARRANTY under the Apache License,
# Version 2.0. Details: <http://www.apache.org/licenses/LICENSE-2.0>

# Note: No library init here. The library init uses this script, so we'd be
# setting ourselves up for infinite recursion.

#
# Main script
#

# Do the checks. This is a function and not just top-level code, so we can avoid
# polluting the global variable namespace.
function check-prereqs {
    local error=0

    if ! which aws >/dev/null 2>&1; then
        error-msg 'Missing `aws` binary.'
        error=1
    fi

    if ! which jq >/dev/null 2>&1; then
        error-msg 'Missing `jq` binary.'
        error=1
    fi

    if [[ ${AWS_ACCESS_KEY_ID} == '' ]]; then
        error-msg 'Missing `AWS_ACCESS_KEY_ID` environment variable.'
        error=1
    fi

    if [[ ${AWS_SECRET_ACCESS_KEY} == '' ]]; then
        error-msg 'Missing `AWS_SECRET_ACCESS_KEY` environment variable.'
        error=1
    fi

    # TODO: Should probably do more stuff!

    return "${error}"
}

check-prereqs || return "$?"
unset -f check-prereqs
