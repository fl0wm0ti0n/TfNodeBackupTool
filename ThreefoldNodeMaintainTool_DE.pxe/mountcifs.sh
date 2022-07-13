#!/bin/bash
# Author: Florian Gabriel (omniflow)
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
mount_cifs() {
    local remote=$1
    local user=$2
    local password=$3
    local mntFolder=$4

    sudo mount -t cifs -o username="$user",password="$password",uid=33,gid=33,file_mode=0770,dir_mode=0770 "$remote" "$mntFolder"
}

write_help() {
    [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
    echo "-------------------------------------------------------------------"
    echo "Helptext of $0"
    echo "Syntax: $0 [parameters]"
    echo "PARAMETERS:"
    echo "r -> cifs target string like //10.0.0.2/data"
    echo "     -r <//10.0.0.2/data>"
    echo "u -> cifs user"
    echo "     -p <username>"
    echo "p -> cifs password"
    echo "     -p <password>"
    echo "m -> Mountpoint"
    echo "     -r </mnt/folder/>"
    echo "-------------------------------------------------------------------"
    echo "made by omniflow [https://github.com/fl0wm0ti0n]"
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
}

##################
###### MAIN ######
##################
echo "Try to mount cifs share ..."

while getopts 'r:u:p:m:h' OPTION; do
case "$OPTION" in
    r)
        remote="$OPTARG"
    ;;
    u)
        user="$OPTARG"
    ;;
    p)
        password="$OPTARG"
    ;;
    m)
        mntFolder="$OPTARG"
    ;;
    h)
        write_help
    ;;
    ?)
        write_help
    ;;
esac
done
shift "$((OPTIND -1))"

if [ -z "$remote" ] || [ -z "$user" ] || [ -z "$password" ] || [ -z "$mntFolder" ] ;then
[ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
echo "Enter cifs share and credentials"
read  -r -p "Enter cifs remote e.g '//10.0.0.15/sharedfolder':" remote;
read  -r -p "Enter cifs username:" user;
read  -r -p "Enter cifs password:" password;
read  -r -p "Enter Mountpoint (path will be created if not exist):" mntFolder;
[ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
fi

mkdir -p "$mntFolder"
mount_cifs "$remote" "$user" "$password" "$mntFolder"
exit 0