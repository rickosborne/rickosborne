#!/bin/bash

SCRIPT_DIR="${BASH_SOURCE%/*}" ; [[ -d "$SCRIPT_DIR" ]] || SCRIPT_DIR="$PWD"

function failure {
    echo -e "$ERROR_ICON $1"
    exit 1
}

function dashed {
    if [ -z $(echo "$1" | grep -- -) ] ; then
        echo ''
    else
        echo 1
    fi
}

function confirm {
    CONFIRM_PROMPT="$2"
    [ -z "$CONFIRM_PROMPT" ] && CONFIRM_PROMPT="Are you sure? (Y/[N]) "
    echo -e "$QUERY_ICON $1"
    read -p "$CONFIRM_PROMPT" CONFIRM_CHOICE
    case "$CONFIRM_CHOICE" in
        y|Y) ;;
        *) echo "$3" ; exit 1 ;;
    esac
}

function is_remote {
    if [ -z $(git remote | grep "$1") ] ; then
        echo ''
    else
        echo 1
    fi
}

function is_remote_branch {
    if [ -z `git branch -r | grep -e "^\\s*${1}\$"` ] ; then
        echo ''
    else
        echo 1
    fi
}

function empty_commit {
    echo -e "$1" | git commit --allow-empty --file -
}

function color_ticket {
    [ "$1" == "dark" ] && echo -e "$DBLUE$2$NOCOLOR"
    [ "$1" != "dark" -a "$1" != "" ] && echo -e "$LBLUE$1$NOCOLOR"
    [ "$1" != "dark" -a "$1" == "" ] && echo -e "${LBLUE}branch$NOCOLOR"
}

function color_branch {
    [ "$1" == "dark" ] && echo -e "$DPURPLE$2$NOCOLOR"
    [ "$1" != "dark" -a "$1" != "" ] && echo -e "$LPURPLE$1$NOCOLOR"
    [ "$1" != "dark" -a "$1" == "" ] && echo -e "${LPURPLE}branch$NOCOLOR"
}
function dark_branch {
    color_branch dark "$1"
}

function color_remote {
    [ "$1" == "dark" ] && echo -e "$DGREEN$2$NOCOLOR"
    [ "$1" != "dark" -a "$1" != "" ] && echo -e "$LGREEN$1$NOCOLOR"
    [ "$1" != "dark" -a "$1" == "" ] && echo -e "${LGREEN}remote$NOCOLOR"
}
function dark_remote {
    color_remote dark "$1"
}

function color_link {
    echo -e "$LBLUE$1$NOCOLOR"
}

function color_error {
    echo -e "$LRED$1$NOCOLOR"
}

function get_switch {
    if [ "$4" == "-$2" -o "$4" == "--$3" ] ; then
        # echo -e "Found switch $1"
        GETARG_KEY="$1"
        GETARG_VALUE=1
        declare "$GETARG_KEY"="$GETARG_VALUE"
        delayed_echo "$5"
    fi    
}

function get_option {
    # echo "get_arg looking for $1 at $4 in ($2, $3)"
    if [ "$4" == "-$2" -o "$4" == "--$3" ] ; then
        # echo -e "Found arg $1 value $5"
        GETARG_KEY="$1"
        GETARG_SHIFT="<<"
        GETARG_VALUE="$5"
        declare "$GETARG_KEY"="$GETARG_VALUE"
        delayed_echo "$6"
    else
        if [ "${4%%=*}" == "-$2" -o "${4%%=*}" == "--$3" ] ; then
            # echo -e "Found arg $1 value ${4#*=}"
            GETARG_KEY="$1"
            GETARG_VALUE="${4#*=}"
            declare "$GETARG_KEY"="$GETARG_VALUE"
            delayed_echo "$6"
        fi
    fi
}

function get_before {
    GETARG_POSITION=1
}

function get_reset {
    GETARG_SHIFT=""
    GETARG_KEY=""
    GETARG_VALUE=""
}

function delayed_echo {
    if [ "$1" != "" ] ; then
        GETARG_MESSAGE=`eval echo -e "\"$1\""`
        echo -e "$GETARG_MESSAGE"
    fi
}

function get_args {
    # echo "get_args $1/$GETARG_POSITION '$2' '$3' '$GETARG_GOTARG' '${3:0:1}'"
    [ "$1" == "1" ] && GETARG_GOTARG=""
    if [ "$GETARG_GOTARG" == "" -a "${3:0:1}" != "-" ] ; then
        if [ "$2" == "" ] ; then
            (( "$GETARG_POSITION" >= "$1" )) && return 1
        else
            if [ "$GETARG_POSITION" == "$1" ] ; then
                GETARG_POSITION="$[GETARG_POSITION + 1]"
                GETARG_GOTARG=1
                GETARG_KEY="$2"
                GETARG_VALUE="$3"
                declare -x "$GETARG_KEY"="$GETARG_VALUE"
                # echo "$GETARG_KEY = ${!GETARG_KEY} ($GETARG_VALUE)"
                delayed_echo "$4"
            fi
        fi
    fi
    return 0
}
