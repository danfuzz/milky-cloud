#!/bin/bash
#
# Copyright 2022-2023 the Milky-cloud Authors (Dan Bornstein et alia).
# SPDX-License-Identifier: Apache-2.0

# Helper library for `instance` subcommands that control instances.

# Where the usual info options land when parsed.
_control_infoOpts=()

# Main implementation for control subcommands that issue one of the standard EC2
# commands
function instance-control-ec2 {
    local cmd="$1"
    local label="$2"

    progress-msg --enable

    local instanceInfo
    instanceInfo="$(
        lib instance info --output-array "${_control_infoOpts[@]}"
    )" \
    || exit "$?"

    # We need to extract the region for the ultimate AWS call. This assumes --
    # safely as of this writing -- that all found instances will be in the same
    # region. This also serves to figure out if there were any results at all.
    local region="$(
        jget --output=raw "${instanceInfo}" '.[0].region // "no-results"'
    )"

    if [[ ${region} == 'no-results' ]]; then
        info-msg 'No matching instances found. Not taking action.'
        exit
    fi

    local idsJson="$(jget "${instanceInfo}" 'map(.id)')"

    progress-msg "${label}:"
    info-msg --exec jget --output=raw "${instanceInfo}" '
        .[] | "  \(.id): \(.name)"'

    ec2-json "${cmd}" --loc="${region}" \
        ids:json="${idsJson}" \
        '{ InstanceIds: $ids }' \
        :: --output=none \
    || return "$?"

    progress-msg 'Done.'
}

# Sets up a subcommand to take the usual `instance info` options, storing them
# so they can be found by other parts of this helper library.
function usual-info-opts {
    opt-value --call='{ _control_infoOpts+=(--default-loc="$1") }' default-loc
    opt-value --call='{ _control_infoOpts+=(--default-vpc="$1") }' default-vpc
    opt-value --call='{ _control_infoOpts+=(--expired="$1") }' expired
    opt-value --call='{ _control_infoOpts+=(--id="$1") }' id
    opt-toggle --call='{ _control_infoOpts+=(--multiple="$1") }' multiple
    opt-toggle --call='{ _control_infoOpts+=(--not-found-ok="$1") }' not-found-ok
}
