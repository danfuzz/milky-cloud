# Copyright 2022-2023 the Milky-cloud Authors (Dan Bornstein et alia).
# SPDX-License-Identifier: Apache-2.0


#
# Setup for this sublibrary.
#

# Calls `lib aws-json ec2`.
function ec2-json {
    lib aws-json ec2 "$@"
}

# Is the given value a valid instance ID? This allows for wildcards, though only
# accepts as IDs strings that begin with a literal `i-`. Without a wildcard,
# this requires between 7 and 20 hex digits of ID number.
function is-instance-id {
    [[ $1 =~ ^i-([0-9a-f]*[*][*0-9a-f]*|[0-9a-f]{7,20})$ ]]
}

# Is the given value a valid vpc ID? This allows for wildcards, though only
# accepts as IDs strings that begin with a literal `vpc-`. Without a wildcard,
# this requires between 10 and 20 hex digits of ID number.
function is-vpc-id {
    [[ $1 =~ ^vpc-([0-9a-f]*[*][*0-9a-f]*|[0-9a-f]{10,20})$ ]]
}

# Calls `lib parse-location --input=zone`.
function parse-zone {
    lib parse-location --input=zone "$@"
}

# Calls `lib parse-location --output=region`.
function region-from-location {
    lib parse-location --output=region "$@"
}

# Calls `region-from-location` (above) as an argument filter.
function region-from-location-filter {
    local region
    region="$(lib parse-location --output=region "$@")" \
    && replace-value "${region}"
}
