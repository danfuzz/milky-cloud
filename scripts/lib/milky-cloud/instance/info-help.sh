#!/bin/bash
#
# Copyright 2022-2023 the Milky-cloud Authors (Dan Bornstein et alia).
# SPDX-License-Identifier: Apache-2.0

# Helper library for `instance` subcommands that print out and possibly
# post-process info values.

# Where the `--output` option lands when parsed.
_info_outputStyle=

# Where postprocessing arguments land when parsed.
_info_postProc=()

# Checks output arguments for sanity.
function check-info-output-args {
    if (( ${#_info_postArgs[@]} != 0 )); then
        if [[ ${_info_outputStyle} == 'none' ]]; then
            error-msg 'Cannot do post-processing given `--output=none`.'
            usage --short
            return 1
        fi

        jpostproc --check "${_info_postArgs[@]}" \
        || {
            usage --short
            return 1
        }
    fi
}

# Performs output postprocessing.
function postproc-info-output {
    local infoArray="$1"

    case "${_info_outputStyle}" in
        array)
            jpostproc <<<"${infoArray}" "${_info_postArgs[@]}"
            ;;
        json)
            # Extract the results out of the array, to form a "naked" sequence of
            # JSON objects, and pass that into the post-processor if necessary.
            if (( ${#_info_postArgs[@]} == 0 )); then
                jget "${infoArray}" '.[]'
            else
                jget "${infoArray}" '.[]' | jpostproc "${_info_postArgs[@]}"
            fi
            ;;
        none)
            : # Nothing to do.
            ;;
    esac
}

# Sets up a subcommand to take the usual `instance info` output arguments,
# storing them so they can be found by other parts of this helper library.
function usual-info-output-args {
    # Output style.
    opt-value --var=_info_outputStyle --init=json --enum='array json none' output

    # Optional post-processing arguments.
    rest-arg --var=_info_postArgs post-arg
}
