#!/bin/bash
# Author: Florian Gabriel (omniflow)
# Date: 20220705
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

# functions


# search_disks

# mount device 
    # specific or that with the actual seed on it.
    # choose or search_seed
# umount device

# Copy from remote
    # cifs, scp, ftp ...

# restore seeds

# check which MAC and restore like with it was before saved in tf GraphQl

# read Config

# get arguments