#!/bin/bash
# Author:   Florian Gabriel (omniflow)
# Repo:     https://github.com/fl0wm0ti0n
# Date:     20230319
# Purpose:  Switches the Threefold Network


# Begin of the scripts:
# Load DRBL setting and functions
DRBL_SCRIPT_PATH="${DRBL_SCRIPT_PATH:-/usr/share/drbl}"

. $DRBL_SCRIPT_PATH/sbin/drbl-conf-functions
. /etc/drbl/drbl-ocs.conf
. $DRBL_SCRIPT_PATH/sbin/ocs-functions

# load the setting for clonezilla live.
[ -e /etc/ocs/ocs-live.conf ] && . /etc/ocs/ocs-live.conf
# Load language files. For English, use "en_US.UTF-8".
ask_and_load_lang_set en_US.UTF-8

# The above is almost necessary, it is recommended to include them in your own custom-ocs.
# From here, you can write your own scripts.

# Set up dhcp
dhclient

# functions

# get host ip
ip=$(hostname -I | awk '{print $1}')

# write to pxelinux.cfg/default
cat pxelinux.cfg/default | sed "s/10.0.0.26/$ip/g" > default
mv default pxelinux.cfg/default

