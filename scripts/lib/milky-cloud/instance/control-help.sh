#!/bin/bash
#
# Copyright 2022-2023 the Milky-cloud Authors (Dan Bornstein et alia).
# SPDX-License-Identifier: Apache-2.0

# Helper library for `instance` subcommands that control instances.

. "$(this-cmd-dir)/info-help.sh"

# Where most of the usual info options land when parsed.
_control_infoOpts=()

# Main implementation for control subcommands that issue one of the standard EC2
# commands.
function instance-control-ec2 {
    local cmd="$1"
    local label="$2"

    # No point in defining this before we need it.
    function _control_ec2-impl {
        local cmd
        local ids
        local loc

        while (( $# > 0 )); do
            case "$1" in
                --cmd=*) cmd="${1#*=}" ;;
                --ids=*) ids="${1#*=}" ;;
                --loc=*) loc="${1#*=}" ;;
                *)
                    error-msg $'Shouldn\'t happen!'
                    return 1
            esac
            shift
        done

        ec2-json "${cmd}" --loc="${loc}" \
            ids:json="${ids}" \
            '{ InstanceIds: $ids }' \
            :: --output=none
    }

    instance-control-skeleton "${label}" _control_ec2-impl --cmd="${cmd}" \
    && unset -f _control_ec2-impl
}

# Basic implementation for control subcommands, with a hole for the actual
# control part (function passed by name).
function instance-control-skeleton {
    local label="$1"
    local implFunc="$2"
    shift 2
    local implArgs=("$@")

    check-info-output-args \
    || return "$?"

    progress-msg --enable

    local infoArray
    infoArray="$(
        lib instance info --output=array "${_control_infoOpts[@]}"
    )" \
    || return "$?"

    # We need to extract the region for the ultimate AWS call. This assumes --
    # safely as of this writing -- that all found instances will be in the same
    # region. This also serves to figure out if there were any results at all.
    local region="$(
        jget --output=raw "${infoArray}" '.[0].region // "no-results"'
    )"

    if [[ ${region} == 'no-results' ]]; then
        info-msg 'No matching instances found. Not taking action.'
        postproc-info-output '[]'
        return
    fi

    local idsJson="$(jget "${infoArray}" 'map(.id)')"

    progress-msg "${label}:"
    info-msg --exec jget --output=raw "${infoArray}" '
        .[] | "  \(.id): \(.name)"'

    "${implFunc}" --loc="${region}" --ids="${idsJson}" "${implArgs[@]}" \
    || return "$?"

    progress-msg 'Done.'

    postproc-info-output "${infoArray}"
}

# Sets up a subcommand to take the usual `instance info` arguments, storing them
# so they can be found by other parts of this helper library.
function usual-info-args {
    opt-toggle --call='{ _control_infoOpts+=(--attributes="$1") }' attributes
    opt-value --call='{ _control_infoOpts+=(--default-loc="$1") }' default-loc
    opt-value --call='{ _control_infoOpts+=(--default-vpc="$1") }' default-vpc
    opt-value --call='{ _control_infoOpts+=(--expired="$1") }' expired
    opt-value --call='{ _control_infoOpts+=(--id="$1") }' id
    opt-toggle --call='{ _control_infoOpts+=(--multiple="$1") }' multiple
    opt-toggle --call='{ _control_infoOpts+=(--not-found-ok="$1") }' not-found-ok

    usual-info-output-args
}
