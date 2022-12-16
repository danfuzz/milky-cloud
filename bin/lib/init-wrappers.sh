# Copyright 2022 the Milky-cloud Authors (Dan Bornstein et alia).
# Licensed AS IS and WITHOUT WARRANTY under the Apache License, Version 2.0.
# Details: <http://www.apache.org/licenses/LICENSE-2.0>

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

# Calls `lib json-length`.
function jlength {
    lib json-length "$@"
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
