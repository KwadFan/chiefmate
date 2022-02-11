#!/usr/bin/env bash
# chiefmate - MainsailOS Updater
#
# Copyright (C) 2021 Stephan Wendel <me@stephanwe.de>
#
# This file may be distributed under the terms of the GNU GPLv3 license

# shellcheck enable=require-variable-braces

## Version of chiefmate
function self_version {
    pushd "${CM_BASE_PATH}" &> /dev/null || exit 1
    git describe --always --tags
    popd &> /dev/null || exit 1
}

# Init Trap
trap 'err_exit $? $LINENO' ERR

# Print Error Code and Line to Log
# and kill running jobs
function err_exit {
    if [ "${1}" != "0" ]; then
        log_msg "ERROR: Error ${1} occured on line ${2}"
        log_msg "ERROR: Stopping $(basename "$0")."
        log_msg "Goodbye..."
    fi
    if [ -n "$(jobs -pr)" ]; then
        jobs -pr | while IFS='' read -r job_id; do
            kill "${job_id}"
        done
    fi
    exit 1
}

### Core functions
# dependency check
function check_dep {
    for exe in ${CM_DEPENDS}; do
        # check path of install (coreutils)
        if [ -z "$(command -v "${exe}")" ]; then
            log_msg "Command '${exe}' not found ... [EXITING]"
            exit 127
        fi
    done
}

# compare OS Versions
function compare_os_ver {
    if [ "${CM_OS_VERSION}" == "${CM_OS_PATCH}" ]; then
        echo "0"
    else
        echo "1"
    fi
}

# check updateable
function updateable {
    if [ "$(compare_os_ver)" -eq 1 ]; then
        update_msg
    else
        noupdate_msg
        goodbye_msg
        # exit 0
    fi
}

function run_install {
    if [ ! -f "${CM_BASE_PATH}/patch/install" ]; then
        log_msg "ERROR: No 'install' script found ... [EXITING]"
        exit 1
    else
        # shellcheck disable=SC1094,SC1091
        source "${CM_BASE_PATH}"/patch/install
    fi
}

function run_preinstall {
    if [ -f "${CM_BASE_PATH}/patch/preinstall" ]; then
        log_msg "Found 'preinstall' script, running preinstall ... "
        # shellcheck disable=SC1091
        source "${CM_BASE_PATH}"/patch/preinstall
    fi
}

function run_postinstall {
    if [ -f "${CM_BASE_PATH}/patch/postinstall" ]; then
        log_msg "Found 'postinstall' script, running postinstall ... "
        # shellcheck disable=SC1091
        source "${CM_BASE_PATH}"/patch/postinstall
    fi
}

# compares files and if matching returns 0 else 1
function compare_file {
    local path new old
    path="${1}"
    new="$(sha256sum "${CM_FILE_SYS}""${path}" | awk '{print $1}')"
    old="$(sha256sum "${path}" | awk '{print $1}')"
    if [ -f "${path}" ] && [ "${old}" != "${new}" ]; then
        echo "1"
    else
        echo "0"
    fi
}

function unpack() {
    local bin path owner mode cmd
    bin="$(command -v install)"
    path="${1}"
    owner="${2}"
    mode="${3}"
    # default flags, see 'man install'
    cmd=(-p -b -S -"$(date +%F)")
    # prepare args
    if [ "${owner}" == "root" ]; then
        cmd+=(-g root -o root)
    elif [ "${owner}" == "${CM_BASE_USER}" ]; then
        cmd+=( -g "${CM_BASE_USER}" -o "${CM_BASE_USER}")
    else
        log_msg "No valid user set ... [SKIPPED]"
    fi
    # add mode, if given
    if [ "${#}" -gt 2 ] && [ -n "${mode}" ]; then
        cmd+=(-m "${mode}")
    fi
    # add path
    cmd+=( "${CM_FILE_SYS}""${path}" "${path}" )
    # run
    if [ "${owner}" == "root" ]; then
        sudo "${bin}" "${cmd[@]}"
    else
        sudo -u "${owner}" "${bin}" "${cmd[@]}"
    fi
}

function install_release {
    if [ -f /etc/mainsailos_version ]; then
        sudo rm -f /etc/mainsailos_version
    fi
    if [ "$(compare_file /etc/mainsailos-release)" -eq 1 ] ||
    [ ! -f "/etc/mainsailos-release" ]; then
        log_msg "Install new Release File ..."
        unpack /etc/mainsailos-release root 0644
    fi
}
