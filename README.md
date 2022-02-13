# chiefmate - MainsailOS Updater

## Installation

First

    cd ~
    git clone https://github.com/mainsail-crew/chiefmate.git
    cd chiefmate
    make install

after that add

    [update_manager chiefmate]
    type: git_repo
    path: ~/chiefmate
    origin: https://github.com/mainsail-crew/chiefmate.git

to your **moonraker.conf**

## User specific setup

If you dont want to update specific files,\
simply add a file named

    .cmignore

to your klipper_config Folder.

In that file, put the full path to the file that should not be updated.\
_for example:_

    /home/pi/klipper_config/mainsail.cfg

This will ignore updating that file and places new Versions\
with a .new extension to its location.

---

## logging

All actions performed by the program itself are logged to

    /home/pi/klipper_logs/chiefmate.log

Please use extensivly the 'log_msg' function in your install scripts.\
Every performed step has to be as transparent as possible.

## Structure

---

### filesystem:

Mirrors you root directory on the Install Media.\
Put files here as you would copy to root ( / )

---

### patch:

This folder keeps your scripts.

There are three options.\
preinstall, install and postinstall.

This should be pretty self explaining

---

## Reuseable Functions

---

### log_msg

    log_msg "This is my first log message"

This will print 'This is my first log message' to the log file and also\
on the terminal.

---

### unpack

static files must be stored in filesystem with same structure as on /

    unpack [file] [user] [mode]

ex:

    unpack /boot/example.txt root 0644

This will result in example.txt in /boot with root:root rwxr-xr-x

---

### compare_file

This compares two files, existing and new on in filesystem, \
spits out 1 if files mismatch, 0 if match.

ex:

    compare_file /boot/config.txt

---
