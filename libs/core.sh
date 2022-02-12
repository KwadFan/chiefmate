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

# APT Helper Functions
# Skip apt update if Cache not older than 1 Hour.
function apt_update_skip {
    log_msg "Check APT for updates ..."
    if [ -f "/var/cache/apt/pkgcache.bin" ] && \
    [ "$(($(date +%s)-$(stat -c %Y /var/cache/apt/pkgcache.bin)))" -lt "3600" ];
    then
        log_msg "APT Cache needs no update! [SKIPPED]"
    else
        # force update
        log_msg "APT Cache needs to be updated!"
        log_msg "Running 'apt update' ..."
        apt update --allow-releaseinfo-change | log_output
    fi
}

function is_installed {
    dpkg-query -W | grep -q "${1}" && echo 0 || echo 1
}

function is_in_apt {
    apt-cache policy "${1}" | wc -l
}

function check_install_pkgs {
    ## Build Array from Var
    local missing_pkgs
    for dep in ${1}; do
        # if in apt cache and not installed add to array
        if [ "$(is_in_apt ${dep})" -gt 0 ] && [ "$(is_installed ${dep})" -eq 1 ]; then
            missing_pkgs+=("${dep}")
        #if in apt cache and installed
        elif [ "$(is_in_apt ${dep})" -gt 0 ] && [ "$(is_installed ${dep})" -eq 0 ]; then
            log_msg "Package ${dep} already installed. [SKIPPED]"
        # if not in apt cache and not installed
        else
            log_msg "Missing Package ${dep} not found in Apt Repository. [SKIPPED]"
        fi
    done
    # if missing pkgs install missing else skip that.
    if [ "${#missing_pkgs[@]}" -ne 0 ]; then
        log_msg "${#missing_pkgs[@]} missing Packages..."
        log_msg "Installing ${missing_pkgs[*]}"
        apt install --yes "${missing_pkgs[@]}"
    else
        log_msg "No Dependencies missing... [SKIPPED]"
    fi
}

function full_upgrade {
    log_msg "Check available System Upgrades ..."
    if [ -n "$(apt list --upgradeable 2> /dev/null | sed '1d;/WARNING/d')" ]; then
        log_msg "System Upgrades available, running full upgrade ..."
        sudo apt full-upgrade --yes
    fi
}

