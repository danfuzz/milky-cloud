# Copyright 2022-2023 the Bashy-lib Authors (Dan Bornstein et alia).
# SPDX-License-Identifier: Apache-2.0

#
# Script dispatch and general call helper.
#
# Note that `lib` in particular is what is used by scripts to invoke other
# scripts, and can also be used as the main call to implement a top-level "run
# some subcommand" script (`lib --libs=<my-project> "$@"`).
#


#
# Public functions
#

# Calls an arbitrary command, and then exits the process with the given code.
function call-then-exit {
    local exitCode="$1"
    shift

    "$@"
    exit "${exitCode}"
}

# Includes (sources) a library file with the given name. (`.sh` is appended to
# the name to produce the actual name of the library file.) A file with this
# name must exist at the top level of a sublibrary directory. Additional
# arguments are passed to the included script and become available as `$1` etc.
#
# It is assumed that failure to load a library is a fatal problem. As such, if
# a library isn't found, the process will exit.
function include-lib {
    if (( $# == 0 )); then
        error-msg 'Missing library name.'
        exit 1
    fi

    local incName="$1"
    shift

    if ! _dispatch_is-valid-name "${incName}"; then
        error-msg "include-lib: Invalid library name: ${incName}"
        exit 1
    fi

    incName+='.sh'

    local d
    for d in "${_bashy_libNames[@]}"; do
        local path="${_bashy_libDir}/${d}/${incName}"
        if [[ -f ${path} ]]; then
            # Use a variable name unlikely to conflict with whatever is loaded,
            # and then unset all the other locals before sourcing the script.
            local _dispatch_path="${path}"
            unset d incName path
            . "${_dispatch_path}" "$@" \
            && return \
            || exit "$?"
        fi
    done

    error-msg "include-lib: Not found: ${incName}"
    exit 1
}

# Calls through to an arbitrary library command. Options:
# * `--libs=<names>` -- List simple names (not paths) of the sublibraries to
#   search. Without this, all sublibraries are searched.
# * `--path` -- Prints the path of the script instead of running it.
# * `--quiet` -- Does not print error messages.
#
# After the options, the next argument is taken to be a main command. After
# that, any number of subcommands are accepted as long as they are allowed by
# the main command. See the docs for more details on directory structure. TLDR:
# A subcommand is a directory with a `_run` script in it along with any number
# of other executable scripts or subcommand directories.
#
# As with running a normal shell command, if the command is not found (including
# if the name is invalid), this returns code `127`.
function lib {
    local wantPath=0
    local quiet=0
    local libs=''

    while true; do
        case "$1" in
            --libs=*) libs="${1#*=}"; shift ;;
            --path)   wantPath=1;     shift ;;
            --quiet)  quiet=1;        shift ;;
            *)        break                 ;;
        esac
    done

    if (( $# == 0 )); then
        error-msg 'lib: Missing command name.'
        return 127
    fi

    # These are the "arguments" / "returns" for the call to `_dispatch_find`.
    local beQuiet="${quiet}"
    local args=("$@")
    local libNames=()
    local path=''
    local cmdName=''
    local libNames

    if [[ ${libs} == '' ]]; then
        libNames=("${_bashy_libNames[@]}")
    else
        libNames=(${libs})
    fi

    _dispatch_find || return "$?"

    if (( wantPath )); then
        echo "${path}"
    else
        "${path}" --bashy-dispatched="${cmdName}" "${args[@]}"
    fi
}


#
# Library-internal functions
#

# Finds the named library script, based on the given commandline arguments. This
# uses variables to communicate with its caller (both for efficiency and
# specifically because there's no saner way to pass arrays back and forth):
#
# * `beQuiet` input -- Boolean, whether to suppress error messages.
# * `libNames` input -- An array which names all of the sublibraries to search
#   (just simple names, not paths).
# * `args` input/output -- An array of the base command name and all of the
#   arguments. It is updated to remove all of the words that name the command
#   (including subcommands) that was found.
# * `path` output -- Set to indicate the path of the command that was found.
# * `cmdName` output -- Name of the command that was found. This is a
#   space-separated lists of the words of the command and subcommand(s).
function _dispatch_find {
    if (( ${#args[@]} == 0 )); then
        if (( !beQuiet )); then
            error-msg 'lib: Missing command name.'
        fi
        return 127
    elif ! _dispatch_is-valid-name "${args[0]}"; then
        if (( !beQuiet )); then
            error-msg "lib: Invalid command name: ${args[0]}"
        fi
        return 127
    fi

    local d
    for d in "${libNames[@]}"; do
        _dispatch_find-in-dir "${d}" \
        && return
    done

    if (( !beQuiet )); then
        error-msg "lib: Command not found: ${args[0]}"
    fi
    return 127
}

# Helper for `_dispatch_find`, which does lookup of a command or subcommand
# within a specific directory. Inputs and outputs are as with `_dispatch_find`,
# except this also takes a regular argument indicating the path to the directory
# in which to perform the lookup. Returns non-zero without any message if the
# command was not found.
function _dispatch_find-in-dir {
    local libDir="$1"

    cmdName=''                    # Not `local`: This is returned to the caller.
    path="${_bashy_libDir}/${libDir}" # Ditto.

    local at
    for (( at = 0; at < ${#args[@]}; at++ )); do
        local nextWord="${args[$at]}"
        local nextPath="${path}/${nextWord}"

        if ! _dispatch_is-valid-name "${nextWord}"; then
            # End of search: The next word is not a valid command name.
            break
        elif [[ ! -x ${nextPath} ]]; then
            # End of search: We landed at a non-exsitent path, unexecutable
            # file, or unsearchable directory.
            break
        elif [[ -f ${nextPath} ]]; then
            # We are looking at a regular executable script. Include it in the
            # result, and return it.
            cmdName+=" ${nextWord}"
            path="${nextPath}"
            (( at++ ))
            break
        elif [[ -f "${nextPath}/_run" && -x "${nextPath}/_run" ]]; then
            # We are looking at a valid subcommand directory. Include it in the
            # result, and iterate.
            cmdName+=" ${nextWord}"
            path="${nextPath}"
        else
            # End of search: We landed at a special file (device, etc.).
            break
        fi
    done

    if (( at == 0 )); then
        # Did not find a match at all.
        return 1
    fi

    # Delete the initial space from `cmdName`.
    cmdName="${cmdName:1}"

    # Delete the args that became the command/subcommand.
    args=("${args[@]:$at}")

    if [[ -d ${path} ]]; then
        # Append subcommand directory runner.
        path+='/_run'
    fi
}

# Indicates by return code whether the given name is a syntactically correct
# command / subcommand name, as far as this system is concerned.
function _dispatch_is-valid-name {
    local name="$1"

    if [[ ${name} =~ ^[_a-z][-_.:a-z0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}
