# Copyright 2022 the Milky-cloud Authors (Dan Bornstein et alia).
# Licensed AS IS and WITHOUT WARRANTY under the Apache License, Version 2.0.
# Details: <http://www.apache.org/licenses/LICENSE-2.0>


#
# Setup for this sublibrary.
#

# Calls `lib aws-json ec2`.
function ec2-json {
    lib aws-json ec2 "$@"
}

# Calls `lib parse-location --input-zone`.
function parse-zone {
    lib parse-location --input=zone "$@"
}

# Calls `lib parse-location --print-region`.
function region-from-location {
    lib parse-location --output=region "$@"
}
