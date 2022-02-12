#!/usr/bin/env bash
# chiefmate - MainsailOS Updater
#
# Copyright (C) 2021 Stephan Wendel <me@stephanwe.de>
#
# This file may be distributed under the terms of the GNU GPLv3 license

# shellcheck enable=require-variable-braces

# functions
# make sure logfile exit
# pre 0.5.0 patch
if [ ! -d "/home/${CM_BASE_USER}/klipper_logs/" ]; then
    sudo -u "${CM_BASE_USER}" mkdir -p "/home/${CM_BASE_USER}/klipper_logs/"
fi
if [ ! -f "${CM_LOG_PATH}" ]; then
    sudo -u "${CM_BASE_USER}" touch "${CM_LOG_PATH}"
fi

# initial log message
function init_log {
    log_msg "----------------- $(date +'[%D %T]') -----------------"
    log_msg "chiefmate Version: $(self_version)"
    log_msg "Mainsail OS Version: ${CM_OS_VERSION} (${CM_OS_PATCH})"
}

# Remove existing Log
function clean_log {
    sudo rm -f "${CM_LOG_PATH}"
    echo -e "${CM_LOG_PREFIX} ... Done!"
    echo -e "${CM_LOG_PREFIX} -----------------------------------------------------"
}

# reusable log message
# usage: log_msg "your message will be displayed and written to log"
function log_msg {
    local msg
    msg="${1}"
    echo -e "${CM_LOG_PREFIX} ${msg}" | tr -s ' ' | tee -a "${CM_LOG_PATH}"
}

function log_output {
    while read -r line; do
        log_msg "${line}"
    done
}

# fixed messages
function update_msg {
    log_msg "Your system is out-of-date, update needed!"
}

function noupdate_msg {
    log_msg "Your system is up-to-date, no update needed!"
}

function goodbye_msg {
    log_msg "Enjoy mainsail and MainsailOS"
    log_msg "GoodBye ..."
    log_msg "------------------------------------------------------"
}

function finish_msg {
    log_msg " ... Done!"
    goodbye_msg
}
