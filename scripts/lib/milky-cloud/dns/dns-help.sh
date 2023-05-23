# Copyright 2022-2023 the Milk-prod Authors (Dan Bornstein et alia).
# This project is PROPRIETARY and UNLICENSED.

#
# Helper library for `dns` subcommands.
#

# Waits for a list of changes to be considered "synchronized" by Route53.
function wait-for-dns-sync {
    local changeIds=("$@")

    progress-msg 'Changes:'

    local c
    for c in "${changeIds[@]}"; do
        wait-for-one-dns-change "${c}" \
        || return "$?"
    done
}

# Waits for a single DNS change to be considered "synchronized."
function wait-for-one-dns-change {
    local changeId="$1"

    local n status
    for (( n = 0; n < 40; n++ )); do
        status="$(lib aws-json route53 get-change --global \
            id="${changeId}" '{ Id: $id }' \
            :: --output=raw '.ChangeInfo.Status')" \
        || return "$?"

        if [[ ${status} == 'INSYNC' ]]; then
            progress-msg "  ${changeId}: Synched."
            return
        fi

        if (( n < 3 )); then
            if (( n == 0 )); then
                progress-msg "  ${changeId}: Waiting for synch."
            fi
            sleep 5
        else
            sleep 2
        fi
        if (( (n > 10) && ((n % 5) == 0) )); then
            progress-msg "  ${changeId}: Still waiting."
        fi
    done

    error-msg "Change ${changeId} never settled!"
    error-msg "Last status: ${status}"
    return 1
}
