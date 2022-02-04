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
	@sudo ln -s $(CUR_DIR)/chiefmate /usr/local/bin/
	@sudo cp $(SERVICE_FILE) $(SYSTEMD_DIR)
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
