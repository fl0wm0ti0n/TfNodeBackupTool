#!/bin/bash
# Author: Florian Gabriel (omniflow)
# Date: 20230320
# https://github.com/fl0wm0ti0n

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

# csv pattern
# nodeid;net;mac1;mac2;mac3;mac4;mac5;mac6;
#

# functions

# get lokal mac

# get remote mac / node id / actual net

# 

# read entry

# write entry

