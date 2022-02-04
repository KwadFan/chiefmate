# chiefmate - MainsailOS Updater
#
# Copyright (C) 2021 Stephan Wendel <me@stephanwe.de>
#
# This file may be distributed under the terms of the GNU GPLv3 license

.PHONY: help install unsinstall

# Setup
USER = $(shell whoami)
CUR_DIR = $(shell pwd)
SERVICE_FILE = $(CUR_DIR)/filesystem/etc/systemd/system/chiefmate.service
SYSTEMD_DIR = /etc/systemd/system/
SUDOERS_FILE = $(CUR_DIR)/filesystem/etc/sudoers.d/050_chiefmate


all: help

help:
	@echo "This is intended to install chiefmate."
	@echo ""
	@echo "Some Parts need 'sudo' privileges."
	@echo "You'll be asked for password, if needed."
	@echo ""
	@echo " Usage: make [action]"
	@echo ""
	@echo "  Available actions:"
	@echo ""
	@echo "   install      Installs crowsnest-legacy"
	@echo "   uninstall    Uninstalls crowsnest-legacy"
	@echo ""

install:
	@sudo ln -s $(CUR_DIR)/cm-wrapper /usr/local/bin/chiefmate
	@sudo cp $(SERVICE_FILE) $(SYSTEMD_DIR)
	@sudo cp $(SUDOERS_FILE) /etc/sudoers.d/
	@sudo chmod 0440 /etc/sudoers.d/050_chiefmate
	@sudo chown root:root /etc/sudoers.d/050_chiefmate
	@sudo systemctl enable chiefmate.service
	@echo "chiefmate successful installed ..."
	@echo "Please perform a REBOOT!"
	@echo "GoodBye ..."

uninstall:
	@sudo rm -f /usr/local/bin/chiefmate
	@sudo systemctl disable chiefmate.service
	@sudo rm -f $(SYSTEMD_DIR)/chiefmate.service
	@sudo systemctl daemon-reload
	@echo "chiefmate successful uninstalled ..."
	@echo "Please remove entry from moonraker.conf"
	@echo "and remove chiefmate directory."
