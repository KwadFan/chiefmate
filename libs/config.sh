#!/usr/bin/env bash
# chiefmate - MainsailOS Updater
#
# Copyright (C) 2021 Stephan Wendel <me@stephanwe.de>
#
# This file may be distributed under the terms of the GNU GPLv3 license

# shellcheck enable=require-variable-braces
# shellcheck disable=SC2034

# Dependencies
CM_DEPENDS="install diff git"

# Logging
CM_LOG_PATH="/home/pi/klipper_logs/chiefmate.log"
CM_LOG_PREFIX="$(date +'[%D %T]') chiefmate:"

# User
CM_BASE_USER="pi"

# filesystem
CM_FILE_SYS="${CM_BASE_PATH}/filesystem"

# Mainsail OS Version
if [ -f "/etc/mainsailos-release" ]; then
    CM_OS_VERSION="$(awk '{print $3}' < /etc/mainsailos-release)"
else
    if [ -f "/etc/mainsailos_version" ]; then
        CM_OS_VERSION="$(cat /etc/mainsailos_version)"
    else
        CM_OS_VERSION="Unknown"
    fi
fi

CM_OS_PATCH="0.6.1"
