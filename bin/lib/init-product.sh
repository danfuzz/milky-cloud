# Copyright 2022 the Milky-cloud Authors (Dan Bornstein et alia).
# Licensed AS IS and WITHOUT WARRANTY under the Apache License, Version 2.0.
# Details: <http://www.apache.org/licenses/LICENSE-2.0>

#
# Per-product definitions needed by the product-agnostic top-level library
# initialization script `init.sh`
#

#
# Sibling libraries
#

. "${_init_libDir}/init-wrappers.sh" || return "$?"


#
# Library functions
#

# Gets the name of this product (or "product").
function _init_product-name {
    echo 'milky-cloud'
}

# Performs any prerequisite checks needed by this product.
function _init_check-prerequisites {
    local error=0

    if ! which aws >/dev/null 2>&1; then
        error-msg 'Missing `aws` binary.'
        error=1
    fi

    if ! which jq >/dev/null 2>&1; then
        error-msg 'Missing `jq` binary.'
        error=1
    fi

    # TODO: Should probably do more stuff!

    return "${error}"
}
